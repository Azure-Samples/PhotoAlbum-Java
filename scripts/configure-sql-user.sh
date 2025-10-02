#!/bin/bash
set -e

# This script configures the Container App's managed identity as a database user in Azure SQL Database

# Get environment variables from azd
RESOURCE_GROUP=$(azd env get-values | grep AZURE_RESOURCE_GROUP | cut -d'=' -f2 | tr -d '"')
SQL_SERVER=$(azd env get-values | grep AZURE_SQL_SERVER_NAME | cut -d'=' -f2 | tr -d '"')
SQL_DATABASE=$(azd env get-values | grep AZURE_SQL_DATABASE_NAME | cut -d'=' -f2 | tr -d '"')
CONTAINER_APP=$(azd env get-values | grep AZURE_CONTAINERAPP_NAME | cut -d'=' -f2 | tr -d '"')

echo "Getting Container App managed identity..."
MANAGED_IDENTITY=$(az containerapp show \
  --name $CONTAINER_APP \
  --resource-group $RESOURCE_GROUP \
  --query identity.principalId -o tsv)

echo "Container App Managed Identity: $MANAGED_IDENTITY"

# Get current user's access token for SQL
echo "Getting access token for SQL Database..."
TOKEN=$(az account get-access-token --resource https://database.windows.net --query accessToken -o tsv)

# SQL Server FQDN
SQL_FQDN="${SQL_SERVER}.database.windows.net"

echo "Creating database user for managed identity..."

# Create the user and grant permissions using sqlcmd
# -G enables Azure AD authentication using the current user's credentials
sqlcmd -S $SQL_FQDN -d $SQL_DATABASE -G <<EOF
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = '${CONTAINER_APP}')
BEGIN
    CREATE USER [${CONTAINER_APP}] FROM EXTERNAL PROVIDER;
END
GO

ALTER ROLE db_datareader ADD MEMBER [${CONTAINER_APP}];
ALTER ROLE db_datawriter ADD MEMBER [${CONTAINER_APP}];
ALTER ROLE db_ddladmin ADD MEMBER [${CONTAINER_APP}];
GO

SELECT 'User ${CONTAINER_APP} configured successfully' as Result;
GO
EOF

echo "Database user configuration complete!"
