#!/usr/bin/env pwsh

Write-Host ""
Write-Host "=== Post-Provision: Waiting for Azure role assignments to propagate ===" -ForegroundColor Green

# Get resource names from azd environment
$RESOURCE_GROUP = azd env get-value AZURE_RESOURCE_GROUP
$ACR_NAME = azd env get-value AZURE_CONTAINER_REGISTRY_NAME
$CONTAINERAPP_NAME = azd env get-value AZURE_CONTAINERAPP_NAME

Write-Host ""
Write-Host "Resources:"
Write-Host "  Resource Group: $RESOURCE_GROUP"
Write-Host "  Container App: $CONTAINERAPP_NAME"
Write-Host "  ACR: $ACR_NAME"

# Get Container App Managed Identity Principal ID
Write-Host ""
Write-Host "Getting Container App managed identity..."
$PRINCIPAL_ID = az containerapp show `
  --name $CONTAINERAPP_NAME `
  --resource-group $RESOURCE_GROUP `
  --query "identity.principalId" -o tsv

Write-Host "  Managed Identity: $PRINCIPAL_ID"

# Wait for role assignment to propagate in Azure AD
Write-Host ""
Write-Host "⏳ Waiting 60 seconds for role assignments to propagate in Azure AD..." -ForegroundColor Yellow
Start-Sleep -Seconds 60

# Verify AcrPull role assignment exists
Write-Host ""
Write-Host "Verifying AcrPull role assignment..."
$ACR_ID = az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query "id" -o tsv
$ROLE_CHECK = az role assignment list `
  --assignee $PRINCIPAL_ID `
  --scope $ACR_ID `
  --query "[?roleDefinitionName=='AcrPull'].roleDefinitionName" -o tsv

if ([string]::IsNullOrEmpty($ROLE_CHECK)) {
    Write-Host "  ⚠️  AcrPull role assignment not yet visible - waiting additional 60 seconds..." -ForegroundColor Yellow
    Start-Sleep -Seconds 60

    # Check again
    $ROLE_CHECK = az role assignment list `
      --assignee $PRINCIPAL_ID `
      --scope $ACR_ID `
      --query "[?roleDefinitionName=='AcrPull'].roleDefinitionName" -o tsv

    if ([string]::IsNullOrEmpty($ROLE_CHECK)) {
        Write-Host "  ⚠️  Warning: AcrPull role still not visible, but continuing..." -ForegroundColor Yellow
        Write-Host "     Role propagation may take up to 5 minutes total."
    } else {
        Write-Host "  ✓ AcrPull role assignment verified" -ForegroundColor Green
    }
} else {
    Write-Host "  ✓ AcrPull role assignment verified" -ForegroundColor Green
}

Write-Host ""
Write-Host "✅ Post-provision complete - ready for deployment" -ForegroundColor Green
Write-Host ""
