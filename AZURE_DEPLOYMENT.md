# Azure Deployment Guide

This guide explains how to deploy the PhotoAlbum application to Azure using Azure Developer CLI (azd).

## Prerequisites

1. **Install Azure Developer CLI (azd)**
   ```bash
   # Linux/WSL
   curl -fsSL https://aka.ms/install-azd.sh | bash

   # Windows (PowerShell)
   powershell -ex AllSigned -c "Invoke-RestMethod 'https://aka.ms/install-azd.ps1' | Invoke-Expression"

   # macOS
   brew tap azure/azd && brew install azd
   ```

2. **Install Azure CLI**
   ```bash
   # Follow instructions at: https://docs.microsoft.com/cli/azure/install-azure-cli
   ```

3. **Install Docker**
   - Docker Desktop or Docker Engine must be installed and running
   - https://docs.docker.com/get-docker/

4. **Login to Azure**
   ```bash
   azd auth login
   ```

## Deployment Steps

### Option 1: Using Azure Developer CLI (Recommended)

1. **Initialize the environment** (first time only):
   ```bash
   azd init
   ```

   You'll be prompted to:
   - Enter an environment name (e.g., "dev", "staging", "prod")
   - Select an Azure subscription
   - Select an Azure location (e.g., "eastus", "westus2")

2. **Deploy the application**:
   ```bash
   azd up
   ```

   This single command will:
   - Provision all Azure resources (Container Registry, Container App, SQL Database, Storage Account)
   - Build the Docker image
   - Push the image to Azure Container Registry
   - Deploy the container to Azure Container Apps
   - Configure all environment variables and connections

3. **View the deployed application**:
   ```bash
   azd show
   ```

   Or get the URL directly:
   ```bash
   azd env get-values | grep AZURE_CONTAINERAPP_URL
   ```

### Option 2: Using the Legacy Bash Script

If you prefer the original bash script approach:

```bash
./deploy-to-azure.sh <resource-group-name>
```

Or set `RESOURCE_GROUP` in `.env` and run:
```bash
./deploy-to-azure.sh
```

## Azure Developer CLI Commands

- **Deploy infrastructure and code**: `azd up`
- **Deploy only infrastructure**: `azd provision`
- **Deploy only application code**: `azd deploy`
- **Monitor application**: `azd monitor`
- **View environment values**: `azd env get-values`
- **Delete all resources**: `azd down`

## Resources Created

The deployment creates the following Azure resources:

1. **Resource Group** - Container for all resources
2. **Container Registry** - Stores Docker images
3. **Container Apps Environment** - Managed environment for Container Apps
4. **Container App** - Runs the PhotoAlbum application
5. **SQL Server** - Azure SQL Database server (Entra ID authentication)
6. **SQL Database** - PhotoAlbum database
7. **Storage Account** - Blob storage for photos
8. **Log Analytics Workspace** - Application logs and metrics

## Configuration

Environment variables are automatically configured:

- `ConnectionStrings__DefaultConnection` - SQL Database connection (using Managed Identity)
- `AzureStorage__BlobServiceUri` - Storage account blob endpoint
- `AzureStorage__ContainerName` - Blob container name ("photos")
- `ASPNETCORE_ENVIRONMENT` - Set to "Production"

## Database Migrations

Database migrations run automatically when the application starts. To run migrations manually:

```bash
# Get the Container App name and Resource Group
RESOURCE_GROUP=$(azd env get-values | grep AZURE_RESOURCE_GROUP | cut -d'=' -f2 | tr -d '"')
CONTAINER_APP=$(azd env get-values | grep AZURE_CONTAINERAPP_NAME | cut -d'=' -f2 | tr -d '"')

# Execute migration command
az containerapp exec \
  --name $CONTAINER_APP \
  --resource-group $RESOURCE_GROUP \
  --command "dotnet ef database update"
```

## Troubleshooting

### View application logs:
```bash
azd monitor --logs
```

Or use Azure CLI:
```bash
RESOURCE_GROUP=$(azd env get-values | grep AZURE_RESOURCE_GROUP | cut -d'=' -f2 | tr -d '"')
CONTAINER_APP=$(azd env get-values | grep AZURE_CONTAINERAPP_NAME | cut -d'=' -f2 | tr -d '"')

az containerapp logs show \
  --name $CONTAINER_APP \
  --resource-group $RESOURCE_GROUP \
  --follow
```

### Redeploy the application:
```bash
azd deploy
```

### Update infrastructure only:
```bash
azd provision
```

### Clean up all resources:
```bash
azd down
```

## Cost Considerations

The default deployment uses Basic/Free tiers:
- Container App: Consumption-based (pay per use)
- SQL Database: Basic tier
- Storage Account: Standard LRS
- Container Registry: Basic tier

Estimated monthly cost: $5-20 USD (depending on usage)

To delete all resources and stop charges:
```bash
azd down --purge
```

## Differences from Legacy Script

The Azure Developer CLI approach provides:

1. **Infrastructure as Code** - Bicep templates define all resources
2. **Environment Management** - Multiple environments (dev, staging, prod)
3. **Reproducible Deployments** - Consistent deployments across teams
4. **Integrated Monitoring** - Built-in `azd monitor` command
5. **Service Hooks** - Pre/post deployment automation
6. **Better Secrets Management** - Automatic handling of sensitive values

The legacy `deploy-to-azure.sh` script is still available for backwards compatibility.
