# This script configures the Container App's managed identity as a database user in Azure SQL Database

Write-Host "Getting environment variables from azd..." -ForegroundColor Yellow

$env_values = azd env get-values | ConvertFrom-StringData
$RESOURCE_GROUP = $env_values.AZURE_RESOURCE_GROUP
$SQL_SERVER = $env_values.AZURE_SQL_SERVER_NAME
$SQL_DATABASE = $env_values.AZURE_SQL_DATABASE_NAME
$CONTAINER_APP = $env_values.AZURE_CONTAINERAPP_NAME

Write-Host "Resource Group: $RESOURCE_GROUP" -ForegroundColor Cyan
Write-Host "SQL Server: $SQL_SERVER" -ForegroundColor Cyan
Write-Host "SQL Database: $SQL_DATABASE" -ForegroundColor Cyan
Write-Host "Container App: $CONTAINER_APP" -ForegroundColor Cyan

Write-Host "`nGetting Container App managed identity..." -ForegroundColor Yellow
$MANAGED_IDENTITY = az containerapp show `
  --name $CONTAINER_APP `
  --resource-group $RESOURCE_GROUP `
  --query identity.principalId -o tsv

Write-Host "Container App Managed Identity: $MANAGED_IDENTITY" -ForegroundColor Cyan

# SQL Server FQDN
$SQL_FQDN = "${SQL_SERVER}.database.windows.net"

Write-Host "`nGetting access token for SQL Database..." -ForegroundColor Yellow
$TOKEN = az account get-access-token --resource https://database.windows.net --query accessToken -o tsv

Write-Host "`nCreating database user for managed identity..." -ForegroundColor Yellow

# Create SQL commands
$sqlCommands = @"
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = '$CONTAINER_APP')
BEGIN
    CREATE USER [$CONTAINER_APP] FROM EXTERNAL PROVIDER;
END
GO

ALTER ROLE db_datareader ADD MEMBER [$CONTAINER_APP];
ALTER ROLE db_datawriter ADD MEMBER [$CONTAINER_APP];
ALTER ROLE db_ddladmin ADD MEMBER [$CONTAINER_APP];
GO

SELECT 'User $CONTAINER_APP configured successfully' as Result;
GO
"@

# Save to temp file
$tempFile = [System.IO.Path]::GetTempFileName()
$sqlCommands | Out-File -FilePath $tempFile -Encoding utf8

try {
    # Execute using sqlcmd with Azure AD authentication
    # -G enables Azure AD authentication using the current user's credentials
    sqlcmd -S $SQL_FQDN -d $SQL_DATABASE -G -i $tempFile

    Write-Host "`nDatabase user configuration complete!" -ForegroundColor Green
}
catch {
    Write-Host "`nError: $_" -ForegroundColor Red
    Write-Host "`nIf sqlcmd is not installed, you can run these SQL commands manually:" -ForegroundColor Yellow
    Write-Host $sqlCommands -ForegroundColor White
    exit 1
}
finally {
    Remove-Item $tempFile -ErrorAction SilentlyContinue
}
