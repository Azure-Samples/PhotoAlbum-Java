# =====================================================================
# PhotoAlbum-Java - Azure Infrastructure Deployment Script (Windows)
# =====================================================================
# Provisions all Azure resources via Bicep and runs post-provision steps.
# Usage:
#   .\deploy.ps1                                      # prompts for password
#   .\deploy.ps1 -PostgresAdminPassword "MyP@ss!"    # non-interactive
# =====================================================================

param(
    [string]$SubscriptionId     = "6c933f90-8115-4392-90f2-7077c9fa5dbd",
    [string]$ResourceGroupName  = "photoalbum-rg",
    [string]$Location           = "centralus",
    [string]$EnvironmentName    = "photoalbum",
    [string]$PostgresAdminUsername = "pgadmin",
    [string]$PostgresAdminPassword = ""
)

$ErrorActionPreference = "Stop"
$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot   = Split-Path -Parent $ScriptDir

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host " PhotoAlbum-Java - Azure Infrastructure Provisioning  " -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan

# ---- Step 1: Verify Azure CLI ----
Write-Host "`n[1/7] Verifying Azure CLI..." -ForegroundColor Yellow
az --version | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Error "Azure CLI not installed. See https://aka.ms/azure-cli"; exit 1 }

# ---- Step 2: Verify login & set subscription ----
Write-Host "`n[2/7] Verifying Azure login..." -ForegroundColor Yellow
$account = az account show -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { Write-Error "Not logged in. Run 'az login' first."; exit 1 }
Write-Host "  Logged in as : $($account.user.name)"
Write-Host "  Subscription : $($account.name) ($($account.id))"

az account set --subscription $SubscriptionId
if ($LASTEXITCODE -ne 0) { Write-Error "Failed to set subscription $SubscriptionId"; exit 1 }
Write-Host "  Active sub   : $SubscriptionId" -ForegroundColor Green

# ---- Step 3: Install Service Connector extension ----
Write-Host "`n[3/7] Installing serviceconnector-passwordless extension..." -ForegroundColor Yellow
az extension add --name serviceconnector-passwordless --upgrade
if ($LASTEXITCODE -ne 0) { Write-Error "Failed to install extension."; exit 1 }
Write-Host "  Extension ready." -ForegroundColor Green

# ---- Step 4: Prompt for password if not provided ----
if (-not $PostgresAdminPassword) {
    $secPwd = Read-Host "  Enter PostgreSQL admin password" -AsSecureString
    $PostgresAdminPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secPwd)
    )
}

# ---- Step 5: Deploy Bicep template (subscription scope) ----
Write-Host "`n[4/7] Deploying Bicep template..." -ForegroundColor Yellow
$DeploymentName = "photoalbum-$(Get-Date -Format 'yyyyMMddHHmmss')"
$rawOutput = az deployment sub create `
    --name $DeploymentName `
    --location $Location `
    --template-file "$ScriptDir/main.bicep" `
    --parameters "$ScriptDir/main.parameters.json" `
    --parameters postgresAdminPassword=$PostgresAdminPassword `
    --output json

if ($LASTEXITCODE -ne 0) { Write-Error "Bicep deployment failed. Check output above."; exit 1 }

$DeployOutput = $rawOutput | ConvertFrom-Json
Write-Host "  Bicep deployment succeeded!" -ForegroundColor Green

# ---- Step 6: Extract deployment outputs ----
$outputs              = $DeployOutput.properties.outputs
$ContainerAppName     = $outputs.containerAppName.value
$ContainerAppFqdn     = $outputs.containerAppFqdn.value
$AcrName              = $outputs.acrName.value
$AcrLoginServer       = $outputs.acrLoginServer.value
$PostgresServerName   = $outputs.postgresServerName.value
$ManagedIdentityClientId = $outputs.managedIdentityClientId.value
$ManagedIdentityId    = $outputs.managedIdentityId.value
$ManagedIdentityName  = $outputs.managedIdentityName.value
$ActualRG             = $outputs.resourceGroupName.value
$ActualSub            = $outputs.subscriptionId.value

Write-Host "`n[5/7] Deployment Outputs:" -ForegroundColor Yellow
Write-Host "  Container App     : $ContainerAppName"
Write-Host "  Container App FQDN: $ContainerAppFqdn"
Write-Host "  ACR               : $AcrLoginServer"
Write-Host "  PostgreSQL Server : $PostgresServerName"
Write-Host "  Managed Identity  : $ManagedIdentityName (clientId=$ManagedIdentityClientId)"
Write-Host "  Resource Group    : $ActualRG"

# ---- Step 7: Service Connector – Managed Identity to PostgreSQL ----
Write-Host "`n[6/7] Creating Service Connector (Managed Identity → PostgreSQL)..." -ForegroundColor Yellow
$ContainerAppResourceId = "/subscriptions/$ActualSub/resourceGroups/$ActualRG/providers/Microsoft.App/containerApps/$ContainerAppName"

az containerapp connection create postgres-flexible `
    --connection "photoalbum_pg_connection" `
    --user-identity client-id=$ManagedIdentityClientId subs-id=$ActualSub `
    --source-id $ContainerAppResourceId `
    --tg $ActualRG `
    --server $PostgresServerName `
    --database photoalbum `
    --client-type springBoot `
    -c photo-album `
    -y

if ($LASTEXITCODE -ne 0) { Write-Error "Service Connector creation failed."; exit 1 }
Write-Host "  Service Connector created!" -ForegroundColor Green

# ---- Step 8: Write infra-config.md ----
Write-Host "`n[7/7] Writing infra-config.md..." -ForegroundColor Yellow
$infraConfigPath = "$ScriptDir/infra-config.md"
$infraConfigContent = @"
# Azure Resources Config

## Environment Info

| Property | Value |
|----------|-------|
| Subscription ID | ``$ActualSub`` |
| Resource Group | ``$ActualRG`` |
| Location | ``$Location`` |

## Resource List

| Resource Type | Name | Region | Config Details |
|---------------|------|--------|----------------|
| Azure Container Registry | ``$AcrName`` | $Location | Login server: $AcrLoginServer |
| Container Apps Environment | ``azace$(($AcrName -replace 'azacr',''))`` | $Location | Log Analytics connected |
| Azure Container App | ``$ContainerAppName`` | $Location | FQDN: $ContainerAppFqdn, Port: 8080 |
| Azure Database for PostgreSQL Flexible Server | ``$PostgresServerName`` | $Location | FQDN: ${PostgresServerName}.postgres.database.azure.com, DB: photoalbum, Version: 17 |
| User-Assigned Managed Identity | ``$ManagedIdentityName`` | $Location | Client ID: $ManagedIdentityClientId |
| Log Analytics Workspace | ``azlaw$(($AcrName -replace 'azacr',''))`` | $Location | Retention: 30 days |
"@
Set-Content -Path $infraConfigPath -Value $infraConfigContent -Encoding UTF8
Write-Host "  infra-config.md written to: $infraConfigPath" -ForegroundColor Green

Write-Host "`n======================================================" -ForegroundColor Green
Write-Host " Provisioning Complete!" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Green
Write-Host " Resource Group : $ActualRG" -ForegroundColor Green
Write-Host " ACR            : $AcrLoginServer" -ForegroundColor Green
Write-Host " PostgreSQL     : ${PostgresServerName}.postgres.database.azure.com" -ForegroundColor Green
Write-Host " Container App  : https://$ContainerAppFqdn" -ForegroundColor Green
Write-Host "`n Next: Run deploy-scripts/deploy.ps1 to build and push the Docker image." -ForegroundColor Cyan
