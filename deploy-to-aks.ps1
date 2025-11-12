# PhotoAlbum AKS Deployment Script
# This script deploys the Photo Album application to Azure Kubernetes Service

Write-Host "=== Photo Album AKS Deployment ===" -ForegroundColor Cyan
Write-Host ""

# Check if we have kubectl access
Write-Host "Checking kubectl connectivity..." -ForegroundColor Yellow
kubectl cluster-info
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Cannot connect to Kubernetes cluster" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Connected to AKS cluster" -ForegroundColor Green
Write-Host ""

# Prompt for PostgreSQL password
Write-Host "=== Database Configuration ===" -ForegroundColor Cyan
$dbPassword = Read-Host "Enter PostgreSQL password for user 'photoalbum'" -AsSecureString
$dbPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($dbPassword))

if ([string]::IsNullOrWhiteSpace($dbPasswordPlain)) {
    Write-Host "Error: Password cannot be empty" -ForegroundColor Red
    exit 1
}

# Create temporary secret file with actual password
$secretContent = @"
apiVersion: v1
kind: Secret
metadata:
  name: photo-album-db-secret
  namespace: photo-album
type: Opaque
stringData:
  SPRING_DATASOURCE_URL: "jdbc:postgresql://demo-photo-album-33d13-postgresql.postgres.database.azure.com:5432/photoalbum?sslmode=require"
  SPRING_DATASOURCE_USERNAME: "photoalbum"
  SPRING_DATASOURCE_PASSWORD: "$dbPasswordPlain"
"@

$secretContent | Out-File -FilePath "k8s/secret-temp.yaml" -Encoding UTF8
Write-Host "✓ Database secret configured" -ForegroundColor Green
Write-Host ""

# Deploy to Kubernetes
Write-Host "=== Deploying to Kubernetes ===" -ForegroundColor Cyan

Write-Host "Creating namespace..." -ForegroundColor Yellow
kubectl apply -f k8s/namespace.yaml

Write-Host "Creating database secret..." -ForegroundColor Yellow
kubectl apply -f k8s/secret-temp.yaml

Write-Host "Deploying application..." -ForegroundColor Yellow
kubectl apply -f k8s/deployment.yaml

Write-Host "Creating service..." -ForegroundColor Yellow
kubectl apply -f k8s/service.yaml

# Clean up temporary secret file
Remove-Item "k8s/secret-temp.yaml" -Force
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
