#!/usr/bin/env bash
# =====================================================================
# PhotoAlbum-Java - Azure Infrastructure Deployment Script (Linux/macOS)
# =====================================================================
# Provisions all Azure resources via Bicep and runs post-provision steps.
# Usage:
#   ./deploy.sh                                   # prompts for password
#   POSTGRES_ADMIN_PASSWORD="MyP@ss!" ./deploy.sh # non-interactive
# =====================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-6c933f90-8115-4392-90f2-7077c9fa5dbd}"
RESOURCE_GROUP_NAME="${RESOURCE_GROUP_NAME:-photoalbum-rg}"
LOCATION="${LOCATION:-centralus}"
ENVIRONMENT_NAME="${ENVIRONMENT_NAME:-photoalbum}"
POSTGRES_ADMIN_USERNAME="${POSTGRES_ADMIN_USERNAME:-pgadmin}"
POSTGRES_ADMIN_PASSWORD="${POSTGRES_ADMIN_PASSWORD:-}"

echo "======================================================"
echo " PhotoAlbum-Java - Azure Infrastructure Provisioning  "
echo "======================================================"

# ---- Step 1: Verify Azure CLI ----
echo ""
echo "[1/7] Verifying Azure CLI..."
az --version > /dev/null || { echo "ERROR: Azure CLI not installed."; exit 1; }

# ---- Step 2: Verify login & set subscription ----
echo ""
echo "[2/7] Verifying Azure login..."
ACCOUNT_JSON=$(az account show -o json)
echo "  Logged in as: $(echo "$ACCOUNT_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["user"]["name"])')"
az account set --subscription "$SUBSCRIPTION_ID"
echo "  Active subscription: $SUBSCRIPTION_ID"

# ---- Step 3: Install Service Connector extension ----
echo ""
echo "[3/7] Installing serviceconnector-passwordless extension..."
az extension add --name serviceconnector-passwordless --upgrade
echo "  Extension ready."

# ---- Step 4: Prompt for password if not provided ----
if [ -z "$POSTGRES_ADMIN_PASSWORD" ]; then
    read -rsp "  Enter PostgreSQL admin password: " POSTGRES_ADMIN_PASSWORD
    echo ""
fi

# ---- Step 5: Deploy Bicep template (subscription scope) ----
echo ""
echo "[4/7] Deploying Bicep template..."
DEPLOYMENT_NAME="photoalbum-$(date +%Y%m%d%H%M%S)"
DEPLOY_OUTPUT=$(az deployment sub create \
    --name "$DEPLOYMENT_NAME" \
    --location "$LOCATION" \
    --template-file "$SCRIPT_DIR/main.bicep" \
    --parameters "$SCRIPT_DIR/main.parameters.json" \
    --parameters postgresAdminPassword="$POSTGRES_ADMIN_PASSWORD" \
    --output json)

echo "  Bicep deployment succeeded!"

# ---- Step 6: Extract deployment outputs ----
get_output() { echo "$DEPLOY_OUTPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['properties']['outputs']['$1']['value'])"; }

CONTAINER_APP_NAME=$(get_output containerAppName)
CONTAINER_APP_FQDN=$(get_output containerAppFqdn)
ACR_NAME=$(get_output acrName)
ACR_LOGIN_SERVER=$(get_output acrLoginServer)
POSTGRES_SERVER_NAME=$(get_output postgresServerName)
MANAGED_IDENTITY_CLIENT_ID=$(get_output managedIdentityClientId)
MANAGED_IDENTITY_ID=$(get_output managedIdentityId)
MANAGED_IDENTITY_NAME=$(get_output managedIdentityName)
ACTUAL_RG=$(get_output resourceGroupName)
ACTUAL_SUB=$(get_output subscriptionId)

echo ""
echo "[5/7] Deployment Outputs:"
echo "  Container App     : $CONTAINER_APP_NAME"
echo "  Container App FQDN: $CONTAINER_APP_FQDN"
echo "  ACR               : $ACR_LOGIN_SERVER"
echo "  PostgreSQL Server : $POSTGRES_SERVER_NAME"
echo "  Managed Identity  : $MANAGED_IDENTITY_NAME (clientId=$MANAGED_IDENTITY_CLIENT_ID)"
echo "  Resource Group    : $ACTUAL_RG"

# ---- Step 7: Service Connector – Managed Identity to PostgreSQL ----
echo ""
echo "[6/7] Creating Service Connector (Managed Identity -> PostgreSQL)..."
CONTAINER_APP_RESOURCE_ID="/subscriptions/$ACTUAL_SUB/resourceGroups/$ACTUAL_RG/providers/Microsoft.App/containerApps/$CONTAINER_APP_NAME"

az containerapp connection create postgres-flexible \
    --connection "photoalbum_pg_connection" \
    --user-identity client-id="$MANAGED_IDENTITY_CLIENT_ID" subs-id="$ACTUAL_SUB" \
    --source-id "$CONTAINER_APP_RESOURCE_ID" \
    --tg "$ACTUAL_RG" \
    --server "$POSTGRES_SERVER_NAME" \
    --database photoalbum \
    --client-type springBoot \
    -c photo-album \
    -y

echo "  Service Connector created!"

# ---- Step 8: Write infra-config.md ----
echo ""
echo "[7/7] Writing infra-config.md..."
cat > "$SCRIPT_DIR/infra-config.md" <<EOF
# Azure Resources Config

## Environment Info

| Property | Value |
|----------|-------|
| Subscription ID | \`$ACTUAL_SUB\` |
| Resource Group | \`$ACTUAL_RG\` |
| Location | \`$LOCATION\` |

## Resource List

| Resource Type | Name | Region | Config Details |
|---------------|------|--------|----------------|
| Azure Container Registry | \`$ACR_NAME\` | $LOCATION | Login server: $ACR_LOGIN_SERVER |
| Container Apps Environment | \`$(echo "$ACR_NAME" | sed 's/azacr/azace/')\` | $LOCATION | Log Analytics connected |
| Azure Container App | \`$CONTAINER_APP_NAME\` | $LOCATION | FQDN: $CONTAINER_APP_FQDN, Port: 8080 |
| Azure Database for PostgreSQL Flexible Server | \`$POSTGRES_SERVER_NAME\` | $LOCATION | FQDN: ${POSTGRES_SERVER_NAME}.postgres.database.azure.com, DB: photoalbum, Version: 17 |
| User-Assigned Managed Identity | \`$MANAGED_IDENTITY_NAME\` | $LOCATION | Client ID: $MANAGED_IDENTITY_CLIENT_ID |
| Log Analytics Workspace | \`$(echo "$ACR_NAME" | sed 's/azacr/azlaw/')\` | $LOCATION | Retention: 30 days |
EOF
echo "  infra-config.md written."

echo ""
echo "======================================================"
echo " Provisioning Complete!"
echo "======================================================"
echo " Resource Group : $ACTUAL_RG"
echo " ACR            : $ACR_LOGIN_SERVER"
echo " PostgreSQL     : ${POSTGRES_SERVER_NAME}.postgres.database.azure.com"
echo " Container App  : https://$CONTAINER_APP_FQDN"
echo ""
echo " Next: Run deploy-scripts/deploy.ps1 to build and push the Docker image."
