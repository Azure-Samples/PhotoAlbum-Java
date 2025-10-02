#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Photo Album Deployment to Azure ===${NC}"

# Load .env file if it exists
if [ -f .env ]; then
  echo -e "${YELLOW}Loading configuration from .env file...${NC}"
  export $(grep -v '^#' .env | xargs)
fi

# Check for required parameters
if [ -z "$1" ] && [ -z "$RESOURCE_GROUP" ]; then
  echo -e "${RED}Error: Resource group name is required${NC}"
  echo "Usage: ./deploy-to-azure.sh <resource-group-name>"
  echo "   Or: Set RESOURCE_GROUP in .env file"
  echo "Example: ./deploy-to-azure.sh photo-album-resources-a3f2c1"
  exit 1
fi

# Command line argument takes precedence over .env
if [ ! -z "$1" ]; then
  RESOURCE_GROUP=$1
fi

# Verify resource group exists
echo -e "${YELLOW}Verifying resource group: $RESOURCE_GROUP${NC}"
if ! az group show --name $RESOURCE_GROUP &> /dev/null; then
  echo -e "${RED}Error: Resource group '$RESOURCE_GROUP' does not exist${NC}"
  exit 1
fi

# Get resources from the resource group
echo -e "${YELLOW}Retrieving Azure resources...${NC}"

ACR_NAME=$(az acr list --resource-group $RESOURCE_GROUP --query "[0].name" -o tsv | tr -d '\r')
ACA_NAME=$(az containerapp list --resource-group $RESOURCE_GROUP --query "[0].name" -o tsv | tr -d '\r')
SQL_SERVER_NAME=$(az sql server list --resource-group $RESOURCE_GROUP --query "[0].name" -o tsv | tr -d '\r')
SQL_DATABASE_NAME=$(az sql db list --resource-group $RESOURCE_GROUP --server $SQL_SERVER_NAME --query "[?name!='master'] | [0].name" -o tsv | tr -d '\r')
STORAGE_ACCOUNT_NAME=$(az storage account list --resource-group $RESOURCE_GROUP --query "[0].name" -o tsv | tr -d '\r')

if [ -z "$ACR_NAME" ] || [ -z "$ACA_NAME" ] || [ -z "$SQL_SERVER_NAME" ] || [ -z "$STORAGE_ACCOUNT_NAME" ]; then
  echo -e "${RED}Error: Could not find all required resources in resource group${NC}"
  exit 1
fi

echo -e "${GREEN}Found resources:${NC}"
echo -e "  ACR: $ACR_NAME"
echo -e "  Container App: $ACA_NAME"
echo -e "  SQL Server: $SQL_SERVER_NAME"
echo -e "  SQL Database: $SQL_DATABASE_NAME"
echo -e "  Storage Account: $STORAGE_ACCOUNT_NAME"

# Get ACR login server
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query "loginServer" -o tsv | tr -d '\r')

# Generate unique image tag
TIMESTAMP=$(date +%m%d%H%M%S)
RANDOM_STR=$(openssl rand -hex 3)
IMAGE_TAG="v${TIMESTAMP}-${RANDOM_STR}"
IMAGE_NAME="$ACR_LOGIN_SERVER/photoalbum:$IMAGE_TAG"

echo -e "${GREEN}Using image tag: $IMAGE_TAG${NC}"

echo ""
echo -e "${YELLOW}Building and pushing Docker image...${NC}"

# Create Dockerfile if it doesn't exist
if [ ! -f "Dockerfile" ]; then
  echo -e "${YELLOW}Creating Dockerfile...${NC}"
  cat > Dockerfile << 'EOF'
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY ["PhotoAlbum/PhotoAlbum.csproj", "PhotoAlbum/"]
RUN dotnet restore "PhotoAlbum/PhotoAlbum.csproj"
COPY . .
WORKDIR "/src/PhotoAlbum"
RUN dotnet build "PhotoAlbum.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "PhotoAlbum.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "PhotoAlbum.dll"]
EOF
fi

# Build and push the Docker image
echo -e "${YELLOW}Building Docker image: $IMAGE_NAME${NC}"
docker build --no-cache -t $IMAGE_NAME .

echo -e "${YELLOW}Pushing image to ACR...${NC}"
az acr login --name $ACR_NAME
docker push $IMAGE_NAME

# Get SQL Server FQDN
SQL_SERVER_FQDN=$(az sql server show --name $SQL_SERVER_NAME --resource-group $RESOURCE_GROUP --query "fullyQualifiedDomainName" -o tsv | tr -d '\r')

# Build connection string (using Managed Identity for authentication)
CONNECTION_STRING="Server=tcp:${SQL_SERVER_FQDN},1433;Initial Catalog=${SQL_DATABASE_NAME};Authentication=Active Directory Default;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

# Get Storage Account endpoint
STORAGE_ACCOUNT_ENDPOINT=$(az storage account show --name $STORAGE_ACCOUNT_NAME --resource-group $RESOURCE_GROUP --query "primaryEndpoints.blob" -o tsv | tr -d '\r')

# Get Container App Managed Identity Principal ID
echo -e "${YELLOW}Retrieving Container App Managed Identity...${NC}"
ACA_PRINCIPAL_ID=$(az containerapp show \
  --name $ACA_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "identity.principalId" -o tsv)

# Grant AcrPull role to Container App MI on ACR if not already granted
echo -e "${YELLOW}Verifying ACR pull permissions...${NC}"
ACR_ID=$(az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query "id" -o tsv | tr -d '\r')
if ! az role assignment list --assignee $ACA_PRINCIPAL_ID --scope $ACR_ID --query "[?roleDefinitionName=='AcrPull']" -o tsv | grep -q "AcrPull"; then
  echo -e "${YELLOW}Granting AcrPull role to Container App MI...${NC}"
  az role assignment create \
    --assignee $ACA_PRINCIPAL_ID \
    --role "AcrPull" \
    --scope $ACR_ID
  echo -e "${YELLOW}Waiting for role assignment to propagate (15 seconds)...${NC}"
  sleep 15
fi

echo ""
echo -e "${YELLOW}Configuring Container App to use Managed Identity for ACR...${NC}"

# Configure the Container App to use managed identity for ACR
az containerapp registry set \
  --name $ACA_NAME \
  --resource-group $RESOURCE_GROUP \
  --server $ACR_LOGIN_SERVER \
  --identity system

echo ""
echo -e "${YELLOW}Updating Container App ingress to use port 8080...${NC}"
az containerapp ingress update \
  --name $ACA_NAME \
  --resource-group $RESOURCE_GROUP \
  --target-port 8080

echo ""
echo -e "${YELLOW}Updating Container App with new image and configuration...${NC}"

# Update the container app with the new image and environment variables
az containerapp update \
  --name $ACA_NAME \
  --resource-group $RESOURCE_GROUP \
  --image $IMAGE_NAME \
  --set-env-vars \
    "ConnectionStrings__DefaultConnection=$CONNECTION_STRING" \
    "AzureStorageBlob__Endpoint=$STORAGE_ACCOUNT_ENDPOINT" \
    "AzureStorageBlob__ContainerName=photos" \
    "ASPNETCORE_ENVIRONMENT=Production" \
  --cpu 0.5 \
  --memory 1Gi \
  --min-replicas 1 \
  --max-replicas 3

# Get Container App URL
ACA_URL=$(az containerapp show --name $ACA_NAME --resource-group $RESOURCE_GROUP --query "properties.configuration.ingress.fqdn" -o tsv | tr -d '\r')

echo ""
echo -e "${GREEN}=== Deployment Complete ===${NC}"
echo ""
echo -e "${GREEN}Application URL:${NC} https://$ACA_URL"
echo ""
echo -e "${YELLOW}Note: Database migrations will run automatically when the app starts.${NC}"
echo -e "${YELLOW}If you need to run migrations manually, use:${NC}"
echo -e "  az containerapp exec --name $ACA_NAME --resource-group $RESOURCE_GROUP --command \"dotnet ef database update\""
