#!/bin/bash
set -e

echo ""
echo "=== Pre-Deploy: Configuring Container App ACR authentication ==="

# Get resource names from azd environment
RESOURCE_GROUP=$(azd env get-value AZURE_RESOURCE_GROUP)
ACR_ENDPOINT=$(azd env get-value AZURE_CONTAINER_REGISTRY_ENDPOINT)
CONTAINERAPP_NAME=$(azd env get-value AZURE_CONTAINERAPP_NAME)

echo ""
echo "Resources:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Container App: $CONTAINERAPP_NAME"
echo "  ACR Endpoint: $ACR_ENDPOINT"

# Configure Container App to use managed identity for ACR
echo ""
echo "Configuring Container App registry with managed identity..."

if az containerapp registry set \
  --name $CONTAINERAPP_NAME \
  --resource-group $RESOURCE_GROUP \
  --server $ACR_ENDPOINT \
  --identity system > /dev/null 2>&1; then
  echo "  ✓ Container App ACR authentication configured"
else
  echo "  ⚠️  Warning: Failed to configure registry, continuing..."
fi

echo ""
echo "✅ Pre-deploy complete - ready to push image"
echo ""
