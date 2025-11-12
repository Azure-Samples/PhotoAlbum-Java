# PhotoAlbum AKS Deployment Script
# This script deploys the Photo Album application to Azure Kubernetes Service

Write-Host "=== Photo Album AKS Deployment ===" -ForegroundColor Cyan
Write-Host ""

# Load environment variables from .env file
Write-Host "Loading configuration from .env file..." -ForegroundColor Yellow
if (!(Test-Path ".env")) {
    Write-Host "Error: .env file not found in the current directory" -ForegroundColor Red
    exit 1
}

# Parse .env file
$envVars = @{}
Get-Content ".env" | Where-Object { $_ -match "^[^#].*=" } | ForEach-Object {
    $key, $value = $_ -split "=", 2
    $envVars[$key.Trim()] = $value.Trim()
}

# Validate required environment variables
$requiredVars = @("POSTGRES_SERVER", "POSTGRES_USER", "POSTGRES_PASSWORD", "POSTGRES_CONNECTION_STRING", "RESOURCE_GROUP", "AKS_CLUSTER_NAME", "ACR_NAME")
foreach ($var in $requiredVars) {
    if (!$envVars.ContainsKey($var) -or [string]::IsNullOrWhiteSpace($envVars[$var])) {
        Write-Host "Error: Required environment variable '$var' not found or empty in .env file" -ForegroundColor Red
        exit 1
    }
}
Write-Host "✓ Configuration loaded successfully" -ForegroundColor Green
Write-Host ""

# Generate Kubernetes manifests from templates
Write-Host "=== Generating Kubernetes Manifests ===" -ForegroundColor Cyan

# Function to replace placeholders in template files
function Update-Template {
    param(
        [string]$TemplatePath,
        [string]$OutputPath,
        [hashtable]$Variables
    )
    
    if (!(Test-Path $TemplatePath)) {
        Write-Host "Warning: Template file $TemplatePath not found, skipping..." -ForegroundColor Yellow
        return
    }
    
    $content = Get-Content $TemplatePath -Raw
    foreach ($key in $Variables.Keys) {
        $content = $content -replace "{{$key}}", $Variables[$key]
    }
    $content | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "✓ Generated $OutputPath from template" -ForegroundColor Green
}

# Generate deployment.yaml from template
Update-Template -TemplatePath "k8s/deployment.template.yaml" -OutputPath "k8s/deployment.yaml" -Variables $envVars

# Generate secret.yaml from template  
Update-Template -TemplatePath "k8s/secret.template.yaml" -OutputPath "k8s/secret.yaml" -Variables $envVars

Write-Host "✓ Kubernetes manifests generated from .env configuration" -ForegroundColor Green
Write-Host ""

# Build and push Docker image to ACR
Write-Host "=== Building and Pushing Docker Image ===" -ForegroundColor Cyan

# Check if Docker is available
Write-Host "Checking Docker availability..." -ForegroundColor Yellow
docker --version 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Docker is not installed or not available" -ForegroundColor Red
    Write-Host "Please install Docker Desktop and make sure it's running" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Docker is available" -ForegroundColor Green

# Check if Dockerfile exists
if (!(Test-Path "Dockerfile")) {
    Write-Host "Error: Dockerfile not found in the current directory" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Dockerfile found" -ForegroundColor Green

# Get ACR login server
$ACR_LOGIN_SERVER = "$($envVars['ACR_NAME']).azurecr.io"
Write-Host "ACR Login Server: $ACR_LOGIN_SERVER" -ForegroundColor White

# Login to ACR
Write-Host "Logging into Azure Container Registry..." -ForegroundColor Yellow
az acr login --name $envVars['ACR_NAME']

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to login to ACR" -ForegroundColor Red
    exit 1
}

# Build Docker image
Write-Host "Building Docker image..." -ForegroundColor Yellow
docker build -t photo-album:latest .

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to build Docker image" -ForegroundColor Red
    exit 1
}

# Tag image for ACR
Write-Host "Tagging image for ACR..." -ForegroundColor Yellow
docker tag photo-album:latest $ACR_LOGIN_SERVER/photo-album:latest

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to tag Docker image" -ForegroundColor Red
    exit 1
}

# Push image to ACR
Write-Host "Pushing image to ACR..." -ForegroundColor Yellow
docker push $ACR_LOGIN_SERVER/photo-album:latest

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to push Docker image to ACR" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Docker image successfully built and pushed to ACR!" -ForegroundColor Green
Write-Host "✓ Image: $ACR_LOGIN_SERVER/photo-album:latest" -ForegroundColor Green
Write-Host ""

# Get AKS credentials
Write-Host "=== Configuring kubectl for AKS ===" -ForegroundColor Cyan
Write-Host "Getting credentials for AKS cluster: $($envVars['AKS_CLUSTER_NAME'])" -ForegroundColor White
Write-Host "Resource Group: $($envVars['RESOURCE_GROUP'])" -ForegroundColor White

az aks get-credentials --resource-group $envVars['RESOURCE_GROUP'] --name $envVars['AKS_CLUSTER_NAME'] --overwrite-existing
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to get AKS credentials" -ForegroundColor Red
    exit 1
}
Write-Host "✓ AKS credentials configured" -ForegroundColor Green
Write-Host ""

# Check if we have kubectl access
Write-Host "Verifying kubectl connectivity..." -ForegroundColor Yellow
kubectl cluster-info
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Cannot connect to Kubernetes cluster" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Connected to AKS cluster" -ForegroundColor Green
Write-Host ""

# Display configuration being used
Write-Host "=== Configuration Summary ===" -ForegroundColor Cyan
Write-Host "PostgreSQL server: $($envVars['POSTGRES_SERVER'])" -ForegroundColor White
Write-Host "Database user: $($envVars['POSTGRES_USER'])" -ForegroundColor White
Write-Host "ACR Registry: $($envVars['ACR_NAME']).azurecr.io" -ForegroundColor White
Write-Host "AKS Cluster: $($envVars['AKS_CLUSTER_NAME'])" -ForegroundColor White
Write-Host "Resource Group: $($envVars['RESOURCE_GROUP'])" -ForegroundColor White
Write-Host ""

# Deploy to Kubernetes
Write-Host "=== Deploying to Kubernetes ===" -ForegroundColor Cyan

Write-Host "Creating namespace..." -ForegroundColor Yellow
kubectl apply -f k8s/namespace.yaml

Write-Host "Creating database secret..." -ForegroundColor Yellow
kubectl apply -f k8s/secret.yaml

Write-Host "Deploying application..." -ForegroundColor Yellow
kubectl apply -f k8s/deployment.yaml

Write-Host "Creating service..." -ForegroundColor Yellow
kubectl apply -f k8s/service.yaml
Write-Host "✓ Deployment manifests applied" -ForegroundColor Green
Write-Host ""

# Wait for deployment
Write-Host "=== Waiting for deployment ===" -ForegroundColor Cyan
Write-Host "Waiting for pods to be ready (this may take a few minutes)..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app=photo-album -n photo-album --timeout=300s

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Pods are ready" -ForegroundColor Green
} else {
    Write-Host "⚠ Timeout waiting for pods. Check status with: kubectl get pods -n photo-album" -ForegroundColor Yellow
}
Write-Host ""

# Get deployment status
Write-Host "=== Deployment Status ===" -ForegroundColor Cyan
kubectl get pods -n photo-album
Write-Host ""
kubectl get svc -n photo-album
Write-Host ""

# Get external IP
Write-Host "=== Getting External IP ===" -ForegroundColor Cyan
Write-Host "Waiting for LoadBalancer external IP (this may take a few minutes)..." -ForegroundColor Yellow
$externalIP = ""
$timeout = 300
$elapsed = 0
while ([string]::IsNullOrWhiteSpace($externalIP) -and $elapsed -lt $timeout) {
    Start-Sleep -Seconds 10
    $elapsed += 10
    $externalIP = kubectl get svc photo-album -n photo-album -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
    if (![string]::IsNullOrWhiteSpace($externalIP)) {
        break
    }
    Write-Host "Still waiting... ($elapsed seconds)" -ForegroundColor Yellow
}

if (![string]::IsNullOrWhiteSpace($externalIP)) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "✓ Deployment Successful!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Application URL: http://$externalIP" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "You can access your Photo Album application at the URL above." -ForegroundColor White
} else {
    Write-Host "⚠ External IP not assigned yet. Check with: kubectl get svc photo-album -n photo-album" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "Useful commands:" -ForegroundColor Cyan
Write-Host "  View pods:    kubectl get pods -n photo-album" -ForegroundColor White
Write-Host "  View logs:    kubectl logs -l app=photo-album -n photo-album --tail=100 -f" -ForegroundColor White
Write-Host "  View service: kubectl get svc photo-album -n photo-album" -ForegroundColor White
Write-Host ""
