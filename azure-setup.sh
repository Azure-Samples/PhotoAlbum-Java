#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Azure Photo Album Resources Setup ===${NC}"

# Variables
RANDOM_SUFFIX=$(openssl rand -hex 3)
RESOURCE_GROUP="photo-album-resources-${RANDOM_SUFFIX}"
LOCATION="westus3"
ACR_NAME="photoalbumacr$RANDOM"
AKS_NODE_VM_SIZE="Standard_D8ds_v5"
PostgreSQL_NAME="$RESOURCE_GROUP-postgresql"
PostgreSQL_SKU="Standard_D4ads_v5"

echo -e "${YELLOW}Using default subscription...${NC}"
az account show --query "{Name:name, SubscriptionId:id}" -o table

# Create Resource Group
echo -e "${YELLOW}Creating resource group: $RESOURCE_GROUP${NC}"
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION

# Create Azure Container Registry
echo -e "${YELLOW}Creating Azure Container Registry: $ACR_NAME${NC}"
az acr create \
  --name $ACR_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Basic \
  --admin-enabled true

# Create Azure Kubernetes Service (AKS) Cluster
echo -e "${YELLOW}Creating AKS Cluster: ${RESOURCE_GROUP}-aks${NC}"
az aks create \
  --resource-group $RESOURCE_GROUP \
  --name "$RESOURCE_GROUP-aks" \
  --node-count 2 \
  --generate-ssh-keys \
  --location $LOCATION \
  --node-vm-size $AKS_NODE_VM_SIZE

# Create PostgreSQL Flexible Server
echo -e "${YELLOW}Creating PostgreSQL Flexible Server: ${PostgreSQL_NAME}${NC}"
az postgres flexible-server create \
  --resource-group $RESOURCE_GROUP \
  --name $PostgreSQL_NAME \
  --sku-name $PostgreSQL_SKU \
  --location $LOCATION

echo -e "${GREEN}=== Setup Complete ===${NC}"