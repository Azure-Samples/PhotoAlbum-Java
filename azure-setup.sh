#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Azure Photo Album Resources Setup ===${NC}"

# Variables
RANDOM_SUFFIX=$(openssl rand -hex 3)
RESOURCE_GROUP="photo-album-resources-${RANDOM_SUFFIX}"
LOCATION="westus2"
ACA_ENVIRONMENT="photo-album-env"
ACR_NAME="photoalbumacr$RANDOM"
SQL_SERVER_NAME="photo-album-sql-$RANDOM"
SQL_DATABASE_NAME="PhotoAlbumDb"
STORAGE_ACCOUNT_NAME="photoalbumsa$RANDOM"
ACA_NAME="photo-album-app"

echo -e "${YELLOW}Using default subscription...${NC}"
az account show --query "{Name:name, SubscriptionId:id}" -o table

# Create Resource Group
echo -e "${YELLOW}Creating resource group: $RESOURCE_GROUP${NC}"
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION

# Create Azure Container Apps Environment with System Assigned Managed Identity
echo -e "${YELLOW}Creating Azure Container Apps environment: $ACA_ENVIRONMENT${NC}"
az containerapp env create \
  --name $ACA_ENVIRONMENT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION

# Create Azure Container Registry
echo -e "${YELLOW}Creating Azure Container Registry: $ACR_NAME${NC}"
az acr create \
  --name $ACR_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Basic \
  --admin-enabled true

# Wait a few seconds for ACR to be fully provisioned
sleep 5

# Get ACR credentials for local push
echo -e "${YELLOW}Retrieving ACR credentials...${NC}"
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query "username" -o tsv | tr -d '\r')
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query "passwords[0].value" -o tsv | tr -d '\r')
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query "loginServer" -o tsv | tr -d '\r')

echo -e "${GREEN}ACR Login Server: $ACR_LOGIN_SERVER${NC}"
echo -e "${GREEN}ACR Username: $ACR_USERNAME${NC}"

# Login to ACR locally
echo -e "${YELLOW}Logging into ACR locally...${NC}"
echo $ACR_PASSWORD | docker login $ACR_LOGIN_SERVER --username $ACR_USERNAME --password-stdin

# Create Container App with System Assigned Managed Identity (placeholder for now)
echo -e "${YELLOW}Creating Container App with System Assigned Managed Identity: $ACA_NAME${NC}"
az containerapp create \
  --name $ACA_NAME \
  --resource-group $RESOURCE_GROUP \
  --environment $ACA_ENVIRONMENT \
  --image mcr.microsoft.com/azuredocs/containerapps-helloworld:latest \
  --target-port 80 \
  --ingress external \
  --system-assigned

# Get the Container App Managed Identity Principal ID
echo -e "${YELLOW}Retrieving Container App Managed Identity...${NC}"
ACA_PRINCIPAL_ID=$(az containerapp show \
  --name $ACA_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "identity.principalId" -o tsv | tr -d '\r')

echo -e "${GREEN}Container App Managed Identity Principal ID: $ACA_PRINCIPAL_ID${NC}"

# Wait for the managed identity to propagate in Azure AD
echo -e "${YELLOW}Waiting for managed identity to propagate in Azure AD (30 seconds)...${NC}"
sleep 30

# Configure ACR to allow pull from Container App MI
echo -e "${YELLOW}Granting AcrPull role to Container App MI on ACR...${NC}"
ACR_ID=$(az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query "id" -o tsv | tr -d '\r')
az role assignment create \
  --assignee $ACA_PRINCIPAL_ID \
  --role "AcrPull" \
  --scope $ACR_ID

# Create Azure SQL Server
echo -e "${YELLOW}Creating Azure SQL Server: $SQL_SERVER_NAME${NC}"
SQL_ADMIN_USER="sqladmin"
SQL_ADMIN_PASSWORD="P@ssw0rd$(openssl rand -base64 12 | tr -d '/+=' | cut -c1-10)"

az sql server create \
  --name $SQL_SERVER_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --admin-user $SQL_ADMIN_USER \
  --admin-password $SQL_ADMIN_PASSWORD \
  --enable-public-network true

# Configure SQL Server firewall to allow Azure services
echo -e "${YELLOW}Configuring SQL Server firewall...${NC}"
az sql server firewall-rule create \
  --name "AllowAzureServices" \
  --resource-group $RESOURCE_GROUP \
  --server $SQL_SERVER_NAME \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

# Create SQL Database
echo -e "${YELLOW}Creating SQL Database: $SQL_DATABASE_NAME${NC}"
az sql db create \
  --name $SQL_DATABASE_NAME \
  --resource-group $RESOURCE_GROUP \
  --server $SQL_SERVER_NAME \
  --service-objective Basic

# Enable Azure AD authentication and add Container App MI as SQL admin
echo -e "${YELLOW}Configuring Azure AD authentication for SQL Server...${NC}"
az sql server ad-admin create \
  --resource-group $RESOURCE_GROUP \
  --server-name $SQL_SERVER_NAME \
  --display-name $ACA_NAME \
  --object-id $ACA_PRINCIPAL_ID

# Create Storage Account
echo -e "${YELLOW}Creating Storage Account: $STORAGE_ACCOUNT_NAME${NC}"
az storage account create \
  --name $STORAGE_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS \
  --kind StorageV2 \
  --allow-blob-public-access true

# Update storage account network rules to allow access
echo -e "${YELLOW}Updating storage account network rules...${NC}"
az storage account update \
  --name $STORAGE_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP \
  --default-action Allow

# Get Storage Account ID
STORAGE_ACCOUNT_ID=$(az storage account show \
  --name $STORAGE_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "id" -o tsv | tr -d '\r')

# Grant Contributor role to Container App MI on Storage Account
echo -e "${YELLOW}Granting Contributor role to Container App MI on Storage Account...${NC}"
az role assignment create \
  --assignee $ACA_PRINCIPAL_ID \
  --role "Contributor" \
  --scope $STORAGE_ACCOUNT_ID

# Grant Storage Blob Data Contributor role to Container App MI
echo -e "${YELLOW}Granting Storage Blob Data Contributor role to Container App MI...${NC}"
az role assignment create \
  --assignee $ACA_PRINCIPAL_ID \
  --role "Storage Blob Data Contributor" \
  --scope $STORAGE_ACCOUNT_ID

# Create a blob container for photos
echo -e "${YELLOW}Creating blob container 'photos'...${NC}"
STORAGE_ACCOUNT_KEY=$(az storage account keys list \
  --account-name $STORAGE_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "[0].value" -o tsv | tr -d '\r')

az storage container create \
  --name photos \
  --account-name $STORAGE_ACCOUNT_NAME \
  --account-key $STORAGE_ACCOUNT_KEY

# Output summary
echo -e "${GREEN}=== Setup Complete ===${NC}"
echo ""
echo -e "${GREEN}Resource Group:${NC} $RESOURCE_GROUP"
echo -e "${GREEN}Location:${NC} $LOCATION"
echo ""
echo -e "${GREEN}Container Apps Environment:${NC} $ACA_ENVIRONMENT"
echo -e "${GREEN}Container App:${NC} $ACA_NAME"
echo -e "${GREEN}Container App MI Principal ID:${NC} $ACA_PRINCIPAL_ID"
echo ""
echo -e "${GREEN}Azure Container Registry:${NC} $ACR_NAME"
echo -e "${GREEN}ACR Login Server:${NC} $ACR_LOGIN_SERVER"
echo -e "${GREEN}ACR Username:${NC} $ACR_USERNAME"
echo ""
echo -e "${GREEN}SQL Server:${NC} $SQL_SERVER_NAME"
echo -e "${GREEN}SQL Database:${NC} $SQL_DATABASE_NAME"
echo -e "${GREEN}SQL Admin User:${NC} $SQL_ADMIN_USER"
echo -e "${GREEN}SQL Admin Password:${NC} $SQL_ADMIN_PASSWORD"
echo ""
echo -e "${GREEN}Storage Account:${NC} $STORAGE_ACCOUNT_NAME"
echo -e "${GREEN}Blob Container:${NC} photos"
echo ""
echo -e "${YELLOW}Save these credentials securely!${NC}"
echo ""
echo -e "${GREEN}=== Resource Group Name ===${NC}"
echo -e "${GREEN}$RESOURCE_GROUP${NC}"

# Write resource details to .env file
echo -e "${YELLOW}Writing configuration to .env file...${NC}"
cat > .env << EOF
RESOURCE_GROUP=$RESOURCE_GROUP
SQL_DATABASE_NAME=$SQL_DATABASE_NAME
SQL_SERVER_NAME=$SQL_SERVER_NAME
STORAGE_ACCOUNT_NAME=$STORAGE_ACCOUNT_NAME
ACR_NAME=$ACR_NAME
ACR_LOGIN_SERVER=$ACR_LOGIN_SERVER
ACA_NAME=$ACA_NAME
EOF

echo -e "${GREEN}Configuration written to .env${NC}"
