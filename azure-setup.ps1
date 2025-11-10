#!/usr/bin/env pwsh

# Colors for output using ANSI escape codes (works in modern PowerShell)
$RED = "`e[31m"
$GREEN = "`e[32m"
$YELLOW = "`e[33m"
$NC = "`e[0m" # No Color

Write-Host "${GREEN}=== Azure Photo Album Resources Setup ===${NC}" -NoNewline
Write-Host ""

# Variables
$RANDOM_SUFFIX = -join ((1..3) | ForEach-Object { '{0:x}' -f (Get-Random -Maximum 256) })
$RESOURCE_GROUP = "photo-album-resources-${RANDOM_SUFFIX}"
$LOCATION = "westus3"
$ACR_NAME = "photoalbumacr$(Get-Random -Maximum 99999)"
$AKS_NODE_VM_SIZE = "Standard_D8ds_v5"
$PostgreSQL_NAME = "$RESOURCE_GROUP-postgresql"
$PostgreSQL_SKU = "Standard_D4ads_v5"

Write-Host "${YELLOW}Using default subscription...${NC}" -NoNewline
Write-Host ""
az account show --query "{Name:name, SubscriptionId:id}" -o table

if ($LASTEXITCODE -ne 0) {
    Write-Host "${RED}Failed to get Azure account information. Please ensure you are logged in with 'az login'${NC}" -NoNewline
    Write-Host ""
    exit 1
}

# Create Resource Group
Write-Host "${YELLOW}Creating resource group: $RESOURCE_GROUP${NC}" -NoNewline
Write-Host ""
az group create `
    --name $RESOURCE_GROUP `
    --location $LOCATION

if ($LASTEXITCODE -ne 0) {
    Write-Host "${RED}Failed to create resource group${NC}" -NoNewline
    Write-Host ""
    exit 1
}

# Create Azure Container Registry
Write-Host "${YELLOW}Creating Azure Container Registry: $ACR_NAME${NC}" -NoNewline
Write-Host ""
az acr create `
    --name $ACR_NAME `
    --resource-group $RESOURCE_GROUP `
    --location $LOCATION `
    --sku Basic `
    --admin-enabled true

if ($LASTEXITCODE -ne 0) {
    Write-Host "${RED}Failed to create Azure Container Registry${NC}" -NoNewline
    Write-Host ""
    exit 1
}

# Create Azure Kubernetes Service (AKS) Cluster
Write-Host "${YELLOW}Creating AKS Cluster: ${RESOURCE_GROUP}-aks${NC}" -NoNewline
Write-Host ""
az aks create `
    --resource-group $RESOURCE_GROUP `
    --name "$RESOURCE_GROUP-aks" `
    --node-count 2 `
    --generate-ssh-keys `
    --location $LOCATION `
    --node-vm-size $AKS_NODE_VM_SIZE

if ($LASTEXITCODE -ne 0) {
    Write-Host "${RED}Failed to create AKS cluster${NC}" -NoNewline
    Write-Host ""
    exit 1
}

# Create PostgreSQL Flexible Server
Write-Host "${YELLOW}Creating PostgreSQL Flexible Server: ${PostgreSQL_NAME}${NC}" -NoNewline
Write-Host ""
az postgres flexible-server create `
    --resource-group $RESOURCE_GROUP `
    --name $PostgreSQL_NAME `
    --sku-name $PostgreSQL_SKU `
    --location $LOCATION

if ($LASTEXITCODE -ne 0) {
    Write-Host "${RED}Failed to create PostgreSQL Flexible Server${NC}" -NoNewline
    Write-Host ""
    exit 1
}

Write-Host "${GREEN}=== Setup Complete ===${NC}" -NoNewline
Write-Host ""

# Output important information
Write-Host "${GREEN}Resources created successfully:${NC}" -NoNewline
Write-Host ""
Write-Host "Resource Group: $RESOURCE_GROUP"
Write-Host "Container Registry: $ACR_NAME"
Write-Host "AKS Cluster: $RESOURCE_GROUP-aks"
Write-Host "PostgreSQL Server: $PostgreSQL_NAME"
Write-Host "Location: $LOCATION"