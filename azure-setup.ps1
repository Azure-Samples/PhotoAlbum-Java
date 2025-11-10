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
$POSTGRES_ADMIN_USER = "pgadmin"
$POSTGRES_ADMIN_PASSWORD = -join ((1..16) | ForEach-Object { 
    [char](Get-Random -Minimum 33 -Maximum 126)
})

az postgres flexible-server create `
    --resource-group $RESOURCE_GROUP `
    --name $PostgreSQL_NAME `
    --sku-name $PostgreSQL_SKU `
    --location $LOCATION `
    --admin-user $POSTGRES_ADMIN_USER `
    --admin-password $POSTGRES_ADMIN_PASSWORD `
    --public-access 0.0.0.0-255.255.255.255

if ($LASTEXITCODE -ne 0) {
    Write-Host "${RED}Failed to create PostgreSQL Flexible Server${NC}" -NoNewline
    Write-Host ""
    exit 1
}

# Store PostgreSQL credentials in environment variables
Write-Host "${YELLOW}Storing PostgreSQL credentials in environment variables...${NC}" -NoNewline
Write-Host ""
$env:POSTGRES_SERVER = "${PostgreSQL_NAME}.postgres.database.azure.com"
$env:POSTGRES_USER = $POSTGRES_ADMIN_USER
$env:POSTGRES_PASSWORD = $POSTGRES_ADMIN_PASSWORD
$env:POSTGRES_CONNECTION_STRING = "jdbc:postgresql://${env:POSTGRES_SERVER}:5432/postgres?user=${POSTGRES_ADMIN_USER}&password=${POSTGRES_ADMIN_PASSWORD}&sslmode=require"

# Write environment variables to .env file
Write-Host "${YELLOW}Writing environment variables to .env file...${NC}" -NoNewline
Write-Host ""
$SCRIPT_ROOT = Split-Path -Parent $MyInvocation.MyCommand.Path
$ENV_FILE = Join-Path $SCRIPT_ROOT ".env"

$ENV_CONTENT = @"
# Azure PostgreSQL Configuration
POSTGRES_SERVER=$env:POSTGRES_SERVER
POSTGRES_USER=$env:POSTGRES_USER
POSTGRES_PASSWORD=$env:POSTGRES_PASSWORD
POSTGRES_CONNECTION_STRING=$env:POSTGRES_CONNECTION_STRING

# Azure Resources
RESOURCE_GROUP=$RESOURCE_GROUP
ACR_NAME=$ACR_NAME
AKS_CLUSTER_NAME=$RESOURCE_GROUP-aks
LOCATION=$LOCATION
"@

$ENV_CONTENT | Out-File -FilePath $ENV_FILE -Encoding UTF8
Write-Host "${GREEN}Environment variables written to: $ENV_FILE${NC}" -NoNewline
Write-Host ""

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
Write-Host ""
Write-Host "${GREEN}PostgreSQL Connection Details (stored in environment variables and .env file):${NC}" -NoNewline
Write-Host ""
Write-Host "POSTGRES_SERVER: $env:POSTGRES_SERVER"
Write-Host "POSTGRES_USER: $env:POSTGRES_USER"
Write-Host "POSTGRES_PASSWORD: $env:POSTGRES_PASSWORD"
Write-Host "POSTGRES_CONNECTION_STRING: $env:POSTGRES_CONNECTION_STRING"
Write-Host ""
Write-Host "${GREEN}All configuration has been saved to .env file in the project root.${NC}" -NoNewline
Write-Host ""