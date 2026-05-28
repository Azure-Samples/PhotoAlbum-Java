# =====================================================================
# PhotoAlbum-Java - App Deployment Script (Windows PowerShell)
# =====================================================================
# Builds the Docker image, pushes to ACR, and deploys to Azure Container App.
# Run AFTER infra/deploy.ps1 has provisioned the Azure infrastructure.
#
# Usage:
#   .\deploy.ps1 `
#       -AcrName "<acr-name>" `
#       -ContainerAppName "<container-app-name>" `
#       -ResourceGroupName "photoalbum-rg"
# =====================================================================

param(
    [Parameter(Mandatory = $true)]
    [string]$AcrName,

    [Parameter(Mandatory = $true)]
    [string]$ContainerAppName,

    [string]$ResourceGroupName = "photoalbum-rg",
    [string]$SubscriptionId    = "6c933f90-8115-4392-90f2-7077c9fa5dbd",
    [string]$ImageName         = "photo-album",
    [string]$ImageTag          = "latest"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = (Get-Item "$ScriptDir\..\..\..\..\..").FullName

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host " PhotoAlbum-Java - Application Deployment             " -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan

# ---- Step 1: Verify Azure CLI ----
Write-Host "`n[1/4] Verifying Azure CLI login..." -ForegroundColor Yellow
az account set --subscription $SubscriptionId
if ($LASTEXITCODE -ne 0) { Write-Error "Failed to set subscription."; exit 1 }
Write-Host "  Subscription set: $SubscriptionId" -ForegroundColor Green

# ---- Step 2: Build and push Docker image to ACR ----
Write-Host "`n[2/4] Building Docker image via ACR build (az acr build)..." -ForegroundColor Yellow
Write-Host "  ACR     : $AcrName"
Write-Host "  Image   : ${ImageName}:${ImageTag}"
Write-Host "  Context : $RepoRoot"

az acr build `
    --registry $AcrName `
    --image "${ImageName}:${ImageTag}" `
    --file "$RepoRoot\Dockerfile" `
    $RepoRoot

if ($LASTEXITCODE -ne 0) { Write-Error "ACR build/push failed."; exit 1 }
Write-Host "  Docker image built and pushed to ACR!" -ForegroundColor Green

# ---- Step 3: Get ACR login server ----
$AcrLoginServer = (az acr show --name $AcrName --query loginServer -o tsv)
$FullImageRef   = "${AcrLoginServer}/${ImageName}:${ImageTag}"
Write-Host "  Image reference: $FullImageRef"

# ---- Step 4: Deploy new image to Container App ----
Write-Host "`n[3/4] Updating Container App with new image..." -ForegroundColor Yellow
az containerapp update `
    --name $ContainerAppName `
    --resource-group $ResourceGroupName `
    --image $FullImageRef

if ($LASTEXITCODE -ne 0) { Write-Error "Container App update failed."; exit 1 }
Write-Host "  Container App updated!" -ForegroundColor Green

# ---- Step 5: Get and display application URL ----
Write-Host "`n[4/4] Fetching application URL..." -ForegroundColor Yellow
$fqdn = az containerapp show `
    --name $ContainerAppName `
    --resource-group $ResourceGroupName `
    --query properties.configuration.ingress.fqdn -o tsv

Write-Host ""
Write-Host "======================================================" -ForegroundColor Green
Write-Host " Deployment Complete!" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Green
Write-Host " Application URL : https://$fqdn" -ForegroundColor Green
Write-Host " Container App   : $ContainerAppName" -ForegroundColor Green
Write-Host " Image           : $FullImageRef" -ForegroundColor Green
