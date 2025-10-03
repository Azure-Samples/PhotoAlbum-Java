#!/usr/bin/env pwsh

Write-Host ""
Write-Host "=== Pre-Deploy: Configuring Container App ACR authentication ===" -ForegroundColor Green

# Get resource names from azd environment
$RESOURCE_GROUP = azd env get-value AZURE_RESOURCE_GROUP
$ACR_ENDPOINT = azd env get-value AZURE_CONTAINER_REGISTRY_ENDPOINT
$CONTAINERAPP_NAME = azd env get-value AZURE_CONTAINERAPP_NAME

Write-Host ""
Write-Host "Resources:"
Write-Host "  Resource Group: $RESOURCE_GROUP"
Write-Host "  Container App: $CONTAINERAPP_NAME"
Write-Host "  ACR Endpoint: $ACR_ENDPOINT"

# Configure Container App to use managed identity for ACR
Write-Host ""
Write-Host "Configuring Container App registry with managed identity..."

try {
    az containerapp registry set `
      --name $CONTAINERAPP_NAME `
      --resource-group $RESOURCE_GROUP `
      --server $ACR_ENDPOINT `
      --identity system 2>&1 | Out-Null

    Write-Host "  ✓ Container App ACR authentication configured" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️  Warning: Failed to configure registry, continuing..." -ForegroundColor Yellow
    Write-Host "  Error: $_"
}

Write-Host ""
Write-Host "✅ Pre-deploy complete - ready to push image" -ForegroundColor Green
Write-Host ""
