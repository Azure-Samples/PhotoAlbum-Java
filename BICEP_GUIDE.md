# Azure Bicep Infrastructure Guide

## Overview

The PhotoAlbum infrastructure has been rebuilt using **Azure Verified Modules (AVM)** following best practices from the [Cosmos DB quickstart example](https://github.com/Azure-Samples/cosmos-db-nosql-dotnet-quickstart).

## Key Changes

### ✅ What's New

1. **Azure Verified Modules (AVM)**: All resources now use official AVM modules from `br/public:avm/...`
2. **Simplified Structure**: No custom module files - everything in `main.bicep`
3. **Aligned with Shell Scripts**: Matches the working `azure-setup.sh` and `deploy-to-azure.sh` architecture

### 📁 Infrastructure Files

```
infra/
├── main.bicep              # Main infrastructure template using AVM
└── main.parameters.json    # Parameters for azd
```

All custom modules have been removed - AVM provides everything needed.

## Resources Deployed

### Core Infrastructure (using AVM)

1. **Log Analytics Workspace** (`avm/res/operational-insights/workspace:0.9.1`)
   - Required for Container Apps monitoring

2. **Container Apps Environment** (`avm/res/app/managed-environment:0.8.1`)
   - Hosts the Container App
   - Connected to Log Analytics

3. **Container Registry** (`avm/res/container-registry/registry:0.6.0`)
   - Stores Docker images
   - Admin enabled for local push
   - System-assigned managed identity for ACR pull

4. **SQL Server & Database** (`avm/res/sql/server:0.9.1`)
   - Azure SQL Server with AAD authentication
   - PhotoAlbumDb database (Basic tier)
   - Firewall rule for Azure services
   - Container App MI as SQL admin

5. **Storage Account** (`avm/res/storage/storage-account:0.14.3`)
   - Blob storage for photos
   - 'photos' container created automatically
   - Public access enabled

6. **Container App** (`avm/res/app/container-app:0.11.0`)
   - System-assigned managed identity
   - Configured with environment variables
   - Uses managed identity for ACR pull
   - External ingress on port 8080
   - Auto-scaling (1-3 replicas)

### Role Assignments (using AVM)

- **AcrPull**: Container App → Container Registry
- **Storage Blob Data Contributor**: Container App → Storage Account
- **SQL Admin**: Container App MI configured as AAD admin

## Deployment with Azure Developer CLI (azd)

### Initial Setup

```bash
# Initialize (if not already done)
azd init

# Set environment name
azd env new <environment-name>

# Set location
azd env set AZURE_LOCATION westus2
```

### Deploy Infrastructure

```bash
# Provision infrastructure (includes postprovision hook)
azd provision

# Deploy application
azd deploy

# Or do both
azd up
```

### Deployment Hooks

The deployment uses two hooks to ensure proper ACR authentication:

#### 1. Post-Provision Hook

Runs after `azd provision` to wait for role propagation:
1. Waits 60 seconds for ACR role assignment to propagate in Azure AD
2. Verifies the AcrPull role assignment is visible
3. Waits additional 60 seconds if role not yet visible (max 120 seconds total)

**Why needed:** Azure role assignments take 2-5 minutes to propagate globally.

#### 2. Pre-Deploy Hook

Runs before `azd deploy` to configure ACR authentication:
1. Configures Container App to use managed identity for ACR
2. Uses `az containerapp registry set` command
3. Ensures registry configuration is set before image update

**Why needed:** The conditional Bicep registry configuration doesn't always trigger during `azd deploy`, so we explicitly configure it via CLI.

**Complete Flow:**
```
azd provision
  → Bicep creates resources
  → postprovision hook waits for propagation

azd deploy
  → predeploy hook configures ACR auth
  → Build & push image
  → Update Container App
  → ✓ Success!
```

**Platform-specific hooks:**
- Windows: `.ps1` files (PowerShell)
- Linux/macOS: `.sh` files (Bash)

Azure Developer CLI automatically selects the correct version for your platform.

### Key Environment Variables

Azure Developer CLI automatically handles these:

- `AZURE_ENV_NAME` - Environment name
- `AZURE_LOCATION` - Azure region
- `SERVICE_WEB_IMAGE_NAME` - Container image (set by azd deploy)

## Deployment with Shell Scripts (Alternative)

Your existing shell scripts still work perfectly:

```bash
# Setup infrastructure
./azure-setup.sh

# Deploy application
./deploy-to-azure.sh <resource-group-name>
```

## Architecture Alignment

The Bicep deployment now **exactly matches** what the shell scripts create:

| Component | Shell Script | Bicep Template |
|-----------|-------------|----------------|
| Container Apps Environment | ✅ | ✅ |
| Container Registry (ACR) | ✅ | ✅ |
| SQL Server + DB | ✅ | ✅ |
| Storage Account + Container | ✅ | ✅ |
| Container App with MI | ✅ | ✅ |
| AcrPull Role | ✅ | ✅ |
| Storage Blob Role | ✅ | ✅ |
| SQL AAD Admin | ✅ | ✅ |
| Log Analytics | ➕ (Bicep adds this) | ✅ |

## Key Configuration Details

### Container App Settings

- **Image**: Defaults to hello-world, updated by `azd deploy`
- **Port**: 8080 (matches Dockerfile EXPOSE)
- **Resources**: 0.5 CPU, 1Gi memory
- **Scaling**: 1-3 replicas

### Environment Variables (auto-configured)

```bash
ConnectionStrings__DefaultConnection=Server=tcp:...;Authentication=Active Directory Default;...
AzureStorageBlob__Endpoint=https://...blob.core.windows.net/
AzureStorageBlob__ContainerName=photos
ASPNETCORE_ENVIRONMENT=Production
```

### Managed Identity Flow

1. Container App created with system-assigned MI
2. MI granted AcrPull role on Container Registry
3. MI granted Storage Blob Data Contributor on Storage Account
4. MI set as SQL Server AAD admin
5. Connection string uses "Authentication=Active Directory Default"

## Fixed Issues

### SQL Server FQDN Construction
- AVM SQL module doesn't output `fullyQualifiedDomainName`
- Solution: Construct FQDN using `environment().suffixes.sqlServerHostname` for multi-cloud support
- Pattern: `'${sqlServerName}${environment().suffixes.sqlServerHostname}'`

### Azure AD Admin Configuration
- Cannot use module outputs in resource names (BCP120 error)
- Solution: Extract SQL server name as a compile-time variable
- Use variable directly in the AD admin resource name

### Container Apps Environment - Zone Redundancy
- Error: `ZoneRedundant must be disabled if InfrastructureSubnetId is not provided`
- Solution: Explicitly set `zoneRedundant: false` when not using custom VNet
- AVM defaults to zone redundancy which requires a subnet

### SQL Database - Basic Tier Size Limit
- Error: `The tier 'Basic' does not support the database max size '34359738368'`
- Basic tier max size: 2GB (2147483648 bytes)
- Solution: Explicitly set `maxSizeBytes: 2147483648` for Basic tier
- For larger databases, use Standard (S0+) or Premium tiers

### SQL Database - Zone Redundancy
- Error: `Provisioning of zone redundant database/pool is not supported for your current request`
- Basic tier doesn't support zone redundancy
- Solution: Explicitly set `zoneRedundant: false` in database configuration

### Container App - Registry Authentication Timing
- Error: `UNAUTHORIZED: authentication required` when pulling from ACR
- Issue: Azure role assignments can take 2-5 minutes to propagate
- Solution - **Conditional Registry Configuration**:
  1. **Initial provision**: Uses public hello-world image → `registries: []` (empty, no ACR auth needed)
  2. **Deploy**: Uses ACR image → `registries: [ACR config]` (conditionally added based on image name)
  3. **Hook**: Waits 60-120 seconds for role propagation before allowing deployment
- The Bicep uses `contains(webImageName, containerRegistry.outputs.loginServer)` to detect ACR images
- This allows provision to complete quickly, while deploy has proper ACR authentication

### Dependency Management
- Container App outputs can be used in resource properties
- Explicit `dependsOn` only needed for the SQL server module
- Bicep automatically infers dependencies from output references

## Troubleshooting

### Common Issues

1. **AVM Module Not Found**
   ```bash
   # Ensure you have latest Bicep CLI
   az bicep upgrade
   ```

2. **Role Assignment Delays**
   - AAD propagation can take 30-60 seconds
   - Bicep handles this with `dependsOn` chains

3. **Image Pull Errors**
   - Verify AcrPull role assignment exists
   - Check Container App MI has propagated

4. **BCP120 Errors (Deployment-Time Values)**
   - Ensure resource names use compile-time values (variables/parameters)
   - Don't use module outputs in resource name properties
   - Extract names as variables before using in modules

### Useful Commands

```bash
# Validate Bicep template
az bicep build --file infra/main.bicep

# What-if analysis
az deployment group what-if \
  --resource-group <rg-name> \
  --template-file infra/main.bicep \
  --parameters infra/main.parameters.json

# View outputs
az deployment group show \
  --resource-group <rg-name> \
  --name <deployment-name> \
  --query properties.outputs
```

## References

- **Azure Verified Modules**: https://github.com/Azure/bicep-registry-modules
- **Cosmos DB Quickstart Example**: https://github.com/Azure-Samples/cosmos-db-nosql-dotnet-quickstart
- **Container Apps AVM**: https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/app/container-app
- **Azure Developer CLI**: https://learn.microsoft.com/azure/developer/azure-developer-cli/
