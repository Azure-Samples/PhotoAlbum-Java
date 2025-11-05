#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo_info "=== Azure Photo Album Resources Setup ==="

# Variables
RANDOM_SUFFIX=$(openssl rand -hex 3)
RESOURCE_GROUP="photo-album-resources-${RANDOM_SUFFIX}"
LOCATION="Central US"
ACR_NAME="photoalbumacr$RANDOM"
AKS_NODE_VM_SIZE="Standard_D8ds_v5"
POSTGRES_SERVER_NAME="photoalbum-postgres-$(date +%s)"
POSTGRES_ADMIN_USER="photoalbum_admin"
POSTGRES_ADMIN_PASSWORD="P@ssw0rd123!"
POSTGRES_DATABASE_NAME="photoalbum"
POSTGRES_APP_USER="photoalbum"
POSTGRES_APP_PASSWORD="photoalbum"

echo_info "Using default subscription..."
az account show --query "{Name:name, SubscriptionId:id}" -o table

# Create Resource Group
echo_info "Creating resource group: $RESOURCE_GROUP"
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION

# Create PostgreSQL Flexible Server
echo_info "Creating PostgreSQL server: $POSTGRES_SERVER_NAME"
az postgres flexible-server create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$POSTGRES_SERVER_NAME" \
    --location "$LOCATION" \
    --admin-user "$POSTGRES_ADMIN_USER" \
    --admin-password "$POSTGRES_ADMIN_PASSWORD" \
    --version "15" \
    --sku-name "Standard_D2ds_v4" \
    --storage-size "32" \
    --backup-retention "7" \
    --public-access "0.0.0.0" \
    --output none

echo_info "PostgreSQL server created successfully!"

# Create application database
echo_info "Creating database: $POSTGRES_DATABASE_NAME"
az postgres flexible-server db create \
    --resource-group "$RESOURCE_GROUP" \
    --server-name "$POSTGRES_SERVER_NAME" \
    --database-name "$POSTGRES_DATABASE_NAME" \
    --output none

# Configure firewall for Azure services
echo_info "Configuring firewall rules..."
az postgres flexible-server firewall-rule create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$POSTGRES_SERVER_NAME" \
    --rule-name "AllowAzureServices" \
    --start-ip-address "0.0.0.0" \
    --end-ip-address "0.0.0.0" \
    --output none

# Add current IP to firewall
CURRENT_IP=$(curl -s https://api.ipify.org)
if [ -n "$CURRENT_IP" ]; then
    echo_info "Adding your current IP ($CURRENT_IP) to firewall..."
    az postgres flexible-server firewall-rule create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$POSTGRES_SERVER_NAME" \
        --rule-name "AllowCurrentIP" \
        --start-ip-address "$CURRENT_IP" \
        --end-ip-address "$CURRENT_IP" \
        --output none
fi

# Get server FQDN
echo_info "Getting server connection details..."
SERVER_FQDN=$(az postgres flexible-server show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$POSTGRES_SERVER_NAME" \
    --query "fullyQualifiedDomainName" \
    --output tsv)

# Wait a moment for server to be fully ready
echo_info "Waiting for server to be fully ready..."
sleep 30

# Setup application user and tables
echo_info "Setting up database user and tables..."

# Create application user using the more reliable execute command
echo_info "Creating application user..."
az postgres flexible-server execute \
    --name "$POSTGRES_SERVER_NAME" \
    --admin-user "$POSTGRES_ADMIN_USER" \
    --admin-password "$POSTGRES_ADMIN_PASSWORD" \
    --database-name "postgres" \
    --querytext "CREATE USER photoalbum WITH PASSWORD 'photoalbum';" || echo_warning "User may already exist, continuing..."

# Grant database connection privileges
echo_info "Granting database connection privileges..."
az postgres flexible-server execute \
    --name "$POSTGRES_SERVER_NAME" \
    --admin-user "$POSTGRES_ADMIN_USER" \
    --admin-password "$POSTGRES_ADMIN_PASSWORD" \
    --database-name "postgres" \
    --querytext "GRANT CONNECT ON DATABASE photoalbum TO photoalbum;" || echo_warning "Grant may have failed, continuing..."

# Grant schema privileges on the photoalbum database
echo_info "Granting schema privileges..."
az postgres flexible-server execute \
    --name "$POSTGRES_SERVER_NAME" \
    --admin-user "$POSTGRES_ADMIN_USER" \
    --admin-password "$POSTGRES_ADMIN_PASSWORD" \
    --database-name "photoalbum" \
    --querytext "GRANT ALL PRIVILEGES ON SCHEMA public TO photoalbum;" || echo_warning "Schema privileges may have failed, continuing..."

# Grant privileges on future objects (so Hibernate can create and manage tables)
echo_info "Setting up future object privileges for Hibernate..."
az postgres flexible-server execute \
    --name "$POSTGRES_SERVER_NAME" \
    --admin-user "$POSTGRES_ADMIN_USER" \
    --admin-password "$POSTGRES_ADMIN_PASSWORD" \
    --database-name "photoalbum" \
    --querytext "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO photoalbum;" || echo_warning "Default privileges may have failed, continuing..."

echo_info "Database user and schema setup completed! Hibernate will create and manage tables."

# Store the datasource URL for later use
DATASOURCE_URL="jdbc:postgresql://$SERVER_FQDN:5432/$POSTGRES_DATABASE_NAME"
echo_info "Datasource URL: $DATASOURCE_URL"

# Create Azure Container Registry
echo_info "Creating Azure Container Registry: $ACR_NAME"
az acr create \
  --name $ACR_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Basic \
  --admin-enabled true

# Create Azure Kubernetes Service (AKS) Cluster
echo_info "Creating AKS Cluster: ${RESOURCE_GROUP}-aks"
az aks create \
  --resource-group $RESOURCE_GROUP \
  --name "$RESOURCE_GROUP-aks" \
  --node-count 2 \
  --generate-ssh-keys \
  --location $LOCATION \
  --node-vm-size $AKS_NODE_VM_SIZE

# Output connection information
echo ""
echo "================================================================"
echo "Setup Complete!"
echo "================================================================"
echo "Server FQDN: $SERVER_FQDN"
echo "Database: $POSTGRES_DATABASE_NAME"
echo "Application User: $POSTGRES_APP_USER"
echo "Resource Group: $RESOURCE_GROUP_NAME"
echo ""
echo "To connect your application to Azure PostgreSQL:"
echo ""
echo "1. Update your application.properties file:"
echo "   spring.datasource.url=jdbc:postgresql://$SERVER_FQDN:5432/$POSTGRES_DATABASE_NAME"
echo ""
echo "2. Keep your existing username and password:"
echo "   spring.datasource.username=$POSTGRES_APP_USER"
echo "   spring.datasource.password=$POSTGRES_APP_PASSWORD"
echo ""
echo "3. Run your application normally:"
echo "   mvn spring-boot:run"
echo "   or"
echo "   java -jar target/photo-album-*.jar"
echo ""
echo "Your existing application.properties configuration will work with Azure!"
echo "================================================================"

echo_warning "Please save these credentials securely!"
echo_warning "Consider using Azure Key Vault for production deployments."