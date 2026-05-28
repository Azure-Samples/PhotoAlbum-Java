# PhotoAlbum-Java - Azure Infrastructure

## Overview

This directory contains Bicep Infrastructure as Code (IaC) templates for provisioning all Azure resources required by the PhotoAlbum-Java Spring Boot application.

## Architecture

| Resource | Name Pattern | Region | SKU |
|---|---|---|---|
| Resource Group | `photoalbum-rg` | centralus | N/A |
| Container Registry | `azacr{token}` | centralus | Basic |
| Log Analytics Workspace | `azlaw{token}` | centralus | PerGB2018 |
| Container Apps Environment | `azace{token}` | centralus | Consumption |
| Azure Container App | `azca{token}` | centralus | Consumption (0.5 vCPU / 1 GiB) |
| PostgreSQL Flexible Server | `azpgf{token}` | centralus | Standard_B1ms (Burstable) |
| User-Assigned Managed Identity | `azumi{token}` | centralus | N/A |

> `{token}` = `uniqueString(subscriptionId, resourceGroupId, location, environmentName)`

## Prerequisites

- Azure CLI >= 2.55.0 (`az --version`)
- Active Azure subscription with required quotas
- Bicep CLI (installed automatically with Azure CLI)

## Deployment

### Windows (PowerShell)

```powershell
cd infra
.\deploy.ps1
# Prompts for PostgreSQL admin password interactively
# Or: .\deploy.ps1 -PostgresAdminPassword "MySecureP@ss1!"
```

### Linux / macOS (Bash)

```bash
cd infra
chmod +x deploy.sh
./deploy.sh
# Prompts for PostgreSQL admin password interactively
# Or: POSTGRES_ADMIN_PASSWORD="MySecureP@ss1!" ./deploy.sh
```

## Parameters

| Parameter | Default | Description |
|---|---|---|
| `environmentName` | `photoalbum` | Environment label for naming and tagging |
| `location` | `centralus` | Azure region for all resources |
| `resourceGroupName` | `photoalbum-rg` | Resource group name |
| `postgresAdminUsername` | `pgadmin` | PostgreSQL admin username |
| `postgresAdminPassword` | *(required)* | PostgreSQL admin password (secure) |

## File Structure

```
infra/
├── main.bicep              # Subscription-scope entry point (creates RG + calls module)
├── main.parameters.json    # Parameter values (no secrets)
├── modules/
│   └── resources.bicep     # Resource group-scope module (all Azure resources)
├── deploy.ps1              # Windows deployment script
├── deploy.sh               # Linux/macOS deployment script
├── infra-config.md         # Machine-readable resource summary (post-provisioning)
├── compliance.md           # IaC rules compliance report
└── README.md               # This file
```

## Post-Deployment Steps

The deploy scripts automatically:
1. Provision all Azure resources via Bicep
2. Create a Service Connector between the Container App and PostgreSQL using Managed Identity
3. Write `infra-config.md` with actual provisioned resource names

After provisioning, run the app deployment script:
```powershell
.\.github\modernize\modernization-plan\005-deployment-azure-container-apps\deploy-scripts\deploy.ps1
```

## Security Notes

- PostgreSQL uses **Managed Identity** (passwordless) authentication for the application
- No secrets are stored in application configuration or IaC files
- AcrPull role is assigned to the User-Assigned Managed Identity (not admin credentials)
- PostgreSQL admin password is required only for server creation; the app never uses it
