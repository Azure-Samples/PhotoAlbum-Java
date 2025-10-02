targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment (e.g., dev, test, prod)')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Id of the principal to assign database and storage roles to (optional)')
param principalId string = ''

@description('Name/email of the principal for Azure AD login (optional)')
param principalName string = ''

@description('Container image name for the web service (optional, set by azd deploy)')
param webImageName string = ''

// Generate a unique suffix for resource names
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

// Resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${environmentName}-${resourceToken}'
  location: location
  tags: tags
}

// Container Apps Environment
module containerAppsEnvironment 'modules/container-apps-environment.bicep' = {
  name: 'container-apps-environment'
  scope: rg
  params: {
    name: 'cae-${environmentName}-${resourceToken}'
    location: location
    tags: tags
  }
}

// Container Registry
module containerRegistry 'modules/container-registry.bicep' = {
  name: 'container-registry'
  scope: rg
  params: {
    name: 'cr${resourceToken}'
    location: location
    tags: tags
  }
}

// SQL Server and Database
module sqlServer 'modules/sql-server.bicep' = {
  name: 'sql-server'
  scope: rg
  params: {
    name: 'sql-${environmentName}-${resourceToken}'
    location: location
    databaseName: 'photoalbum'
    tags: tags
  }
}

// Storage Account
module storageAccount 'modules/storage-account.bicep' = {
  name: 'storage-account'
  scope: rg
  params: {
    name: 'st${resourceToken}'
    location: location
    containerName: 'photos'
    tags: tags
  }
}

// Container App
module containerApp 'modules/container-app.bicep' = {
  name: 'container-app'
  scope: rg
  params: {
    name: 'ca-${environmentName}-${resourceToken}'
    location: location
    containerAppsEnvironmentId: containerAppsEnvironment.outputs.id
    containerRegistryName: containerRegistry.outputs.name
    sqlServerFqdn: sqlServer.outputs.fqdn
    sqlDatabaseName: sqlServer.outputs.databaseName
    storageAccountBlobEndpoint: storageAccount.outputs.blobEndpoint
    storageContainerName: storageAccount.outputs.containerName
    imageName: webImageName
    tags: union(tags, { 'azd-service-name': 'web' })
  }
}

// Azure AD Admin for SQL Server (for deployment user)
// Note: Disabled for now - configure manually after deployment if needed
// module sqlAdAdmin 'modules/sql-ad-admin.bicep' = if (!empty(principalId) && !empty(principalName)) {
//   name: 'sql-ad-admin'
//   scope: rg
//   params: {
//     sqlServerName: sqlServer.outputs.name
//     principalId: principalId
//     adminLogin: principalName
//   }
// }

module storageRoleAssignment 'modules/storage-role-assignment.bicep' = if (!empty(principalId)) {
  name: 'storage-role-assignment'
  scope: rg
  params: {
    storageAccountName: storageAccount.outputs.name
    principalId: principalId
  }
}

// Role assignments for Container App managed identity
module containerAppSqlRoleAssignment 'modules/sql-role-assignment.bicep' = {
  name: 'container-app-sql-role-assignment'
  scope: rg
  params: {
    sqlServerName: sqlServer.outputs.name
    principalId: containerApp.outputs.identityPrincipalId
  }
}

module containerAppStorageRoleAssignment 'modules/storage-role-assignment.bicep' = {
  name: 'container-app-storage-role-assignment'
  scope: rg
  params: {
    storageAccountName: storageAccount.outputs.name
    principalId: containerApp.outputs.identityPrincipalId
  }
}

// Outputs
output AZURE_LOCATION string = location
output AZURE_RESOURCE_GROUP string = rg.name
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.name
output AZURE_CONTAINERAPP_NAME string = containerApp.outputs.name
output AZURE_CONTAINERAPP_URL string = containerApp.outputs.url
output AZURE_SQL_SERVER_NAME string = sqlServer.outputs.name
output AZURE_SQL_DATABASE_NAME string = sqlServer.outputs.databaseName
output AZURE_STORAGE_ACCOUNT_NAME string = storageAccount.outputs.name
