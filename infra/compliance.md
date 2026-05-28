# IaC Rules Compliance Report

## Deployment Tool: azcli | IaC Type: bicep

### Container App Rules

| Rule | Status | Implementation |
|------|--------|----------------|
| Attach User-Assigned Managed Identity | ✅ Applied | `identity.type = 'UserAssigned'` with `managedIdentity.id` in `userAssignedIdentities` |
| AcrPull role assignment (7f951dda) before Container App | ✅ Applied | `acrPullRoleAssignment` defined before `containerApp`, `dependsOn` added |
| Use managed identity (NOT system) for registry | ✅ Applied | `registries[].identity = managedIdentity.id` |
| Base image: mcr.microsoft.com/azuredocs/containerapps-helloworld:latest | ✅ Applied | `template.containers[0].image` set to MCR hello-world |
| Registry connection via properties.configuration.registries | ✅ Applied | `configuration.registries` array with server + identity |
| Enable CORS via ingress.corsPolicy | ✅ Applied | `corsPolicy` with allowedOrigins `['*']`, methods, and headers |
| Container App Environment connected to Log Analytics | ✅ Applied | `appLogsConfiguration.destination = 'log-analytics'` with customerId + sharedKey |
| Key Vault secrets + role assignments as explicit dependencies | ✅ N/A | App uses Managed Identity; no secrets required |

### PostgreSQL Rules

| Rule | Status | Implementation |
|------|--------|----------------|
| Version 17 or higher | ✅ Applied | `properties.version = '17'` |
| Database not named 'postgres' | ✅ Applied | Database named `photoalbum` |
| Firewall rule: allow Azure Services (0.0.0.0) | ✅ Applied | `AllowAzureServices` firewall rule: startIp/endIp = `0.0.0.0` |
| Post-provision Service Connector (Managed Identity) | ✅ Applied | `az containerapp connection create postgres-flexible` in deploy scripts |
| Service Connector: `--user-identity client-id=XX subs-id=XX` | ✅ Applied | Uses `--user-identity client-id=$MI_CLIENT_ID subs-id=$SUB_ID` |
| Service Connector: `--client-type springBoot` | ✅ Applied | `--client-type springBoot` |
| Service Connector: `-c containername` | ✅ Applied | `-c photo-album` |
| AAD auth enabled for Managed Identity | ✅ Applied | `authConfig.activeDirectoryAuth = 'Enabled'` |

### Container Registry Rules

| Rule | Status | Implementation |
|------|--------|----------------|
| Admin user disabled | ✅ Applied | `properties.adminUserEnabled = false` |
| AcrPull role assigned to managed identity | ✅ Applied | `Microsoft.Authorization/roleAssignments` with roleId `7f951dda` |

### General Bicep Rules

| Rule | Status | Implementation |
|------|--------|----------------|
| Resource token: `uniqueString(sub, rg, location, envName)` | ✅ Applied | `var resourceToken = uniqueString(subscription().id, resourceGroup().id, location, environmentName)` |
| All resources named `az{prefix}{token}` (alphanumeric) | ✅ Applied | azumi, azlaw, azacr, azace, azca, azpgf + token |
| main.bicep + main.parameters.json | ✅ Applied | Both files generated |
| Deployment scripts use Azure CLI (`az deployment`) | ✅ Applied | `az deployment sub create` in deploy.ps1 / deploy.sh |
| `.ps1` for PowerShell, `.sh` for Bash | ✅ Applied | `deploy.ps1` and `deploy.sh` |

### Key Vault Rules

| Rule | Status | Implementation |
|------|--------|----------------|
| Use Key Vault only when app has secrets | ✅ N/A | App uses Managed Identity (passwordless); no Key Vault needed |

### Storage Account Rules

| Rule | Status | Implementation |
|------|--------|----------------|
| Storage account rules | ✅ N/A | No storage account required by this application |
