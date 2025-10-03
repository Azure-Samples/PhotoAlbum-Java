#!/bin/bash
set -e

echo ""
echo "=== Post-Provision: Waiting for Azure role assignments to propagate ==="

# Get resource names from azd environment
RESOURCE_GROUP=$(azd env get-value AZURE_RESOURCE_GROUP)
ACR_NAME=$(azd env get-value AZURE_CONTAINER_REGISTRY_NAME)
CONTAINERAPP_NAME=$(azd env get-value AZURE_CONTAINERAPP_NAME)

echo ""
echo "Resources:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Container App: $CONTAINERAPP_NAME"
echo "  ACR: $ACR_NAME"

# Get Container App Managed Identity Principal ID
echo ""
echo "Getting Container App managed identity..."
PRINCIPAL_ID=$(az containerapp show \
  --name $CONTAINERAPP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "identity.principalId" -o tsv)

echo "  Managed Identity: $PRINCIPAL_ID"

# Wait for role assignment to propagate in Azure AD
echo ""
echo "⏳ Waiting 60 seconds for role assignments to propagate in Azure AD..."
sleep 60

# Verify AcrPull role assignment exists
echo ""
echo "Verifying AcrPull role assignment..."
ACR_ID=$(az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query "id" -o tsv)
ROLE_CHECK=$(az role assignment list \
  --assignee $PRINCIPAL_ID \
  --scope $ACR_ID \
  --query "[?roleDefinitionName=='AcrPull'].roleDefinitionName" -o tsv)

if [ -z "$ROLE_CHECK" ]; then
  echo "  ⚠️  AcrPull role assignment not yet visible - waiting additional 60 seconds..."
  sleep 60

  # Check again
  ROLE_CHECK=$(az role assignment list \
    --assignee $PRINCIPAL_ID \
    --scope $ACR_ID \
    --query "[?roleDefinitionName=='AcrPull'].roleDefinitionName" -o tsv)

  if [ -z "$ROLE_CHECK" ]; then
    echo "  ⚠️  Warning: AcrPull role still not visible, but continuing..."
    echo "     Role propagation may take up to 5 minutes total."
  else
    echo "  ✓ AcrPull role assignment verified"
  fi
else
  echo "  ✓ AcrPull role assignment verified"
fi

echo ""
echo "✅ Post-provision complete - ready for deployment"
echo ""
