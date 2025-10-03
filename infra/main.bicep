metadata description = 'Provisions Azure resources for PhotoAlbum web application with Container Apps, SQL Database, and Blob Storage.'

targetScope = 'resourceGroup'

@minLength(1)
@maxLength(64)
@description('Name of the environment (e.g., dev, test, prod)')
param environmentName string

@description('Primary location for all resources')
param location string = resourceGroup().location

@description('Container image name for the web service (set by azd deploy)')
param webImageName string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

// Generate unique resource names
var resourceToken = toLower(uniqueString(resourceGroup().id, environmentName, location))
var tags = {
  'azd-env-name': environmentName
}

// === Log Analytics Workspace for Container Apps ===
module logAnalytics 'br/public:avm/res/operational-insights/workspace:0.9.1' = {
  name: 'log-analytics-${resourceToken}'
  params: {
    name: 'log-${environmentName}-${resourceToken}'
    location: location
    tags: tags
  }
}

// === Container Apps Environment ===
module containerAppsEnvironment 'br/public:avm/res/app/managed-environment:0.8.1' = {
  name: 'container-apps-environment-${resourceToken}'
  params: {
    name: 'cae-${environmentName}-${resourceToken}'
    location: location
    logAnalyticsWorkspaceResourceId: logAnalytics.outputs.resourceId
    zoneRedundant: false  // Disable zone redundancy since we're not using a custom subnet
    tags: tags
  }
}

// === Container Registry ===
module containerRegistry 'br/public:avm/res/container-registry/registry:0.6.0' = {
  name: 'container-registry-${resourceToken}'
  params: {
    name: 'cr${resourceToken}'
    location: location
    acrAdminUserEnabled: true
    acrSku: 'Basic'
    tags: tags
  }
}

// === SQL Server and Database ===
var sqlServerName = 'sql-${environmentName}-${resourceToken}'
var sqlAdminUser = 'sqladmin'
var sqlAdminPassword = 'P@ssw0rd${uniqueString(resourceGroup().id, environmentName)}'
var sqlDatabaseName = 'PhotoAlbumDb'

module sqlServer 'br/public:avm/res/sql/server:0.9.1' = {
  name: 'sql-server-${resourceToken}'
  params: {
    name: sqlServerName
    location: location
    administratorLogin: sqlAdminUser
    administratorLoginPassword: sqlAdminPassword
    tags: tags
    databases: [
      {
        name: sqlDatabaseName
        skuName: 'Basic'
        skuTier: 'Basic'
        maxSizeBytes: 2147483648  // 2GB - max size for Basic tier
        zoneRedundant: false  // Basic tier doesn't support zone redundancy
      }
    ]
    firewallRules: [
      {
        name: 'AllowAzureServices'
        startIpAddress: '0.0.0.0'
        endIpAddress: '0.0.0.0'
      }
    ]
  }
}

// === Storage Account ===
module storageAccount 'br/public:avm/res/storage/storage-account:0.14.3' = {
  name: 'storage-account-${resourceToken}'
  params: {
    name: 'st${resourceToken}'
    location: location
    kind: 'StorageV2'
    skuName: 'Standard_LRS'
    allowBlobPublicAccess: true
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
    }
    blobServices: {
      containers: [
        {
          name: 'photos'
          publicAccess: 'None'
        }
      ]
    }
    tags: tags
  }
}

// === Container App ===
// Construct SQL Server FQDN manually since AVM doesn't output it
var sqlServerFqdn = '${sqlServerName}${environment().suffixes.sqlServerHostname}'
var sqlConnectionString = 'Server=tcp:${sqlServerFqdn},1433;Initial Catalog=${sqlDatabaseName};Authentication=Active Directory Default;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'

module containerApp 'br/public:avm/res/app/container-app:0.11.0' = {
  name: 'container-app-${resourceToken}'
  params: {
    name: 'ca-${environmentName}-${resourceToken}'
    location: location
    environmentResourceId: containerAppsEnvironment.outputs.resourceId
    tags: union(tags, { 'azd-service-name': 'web' })

    // Managed Identity
    managedIdentities: {
      systemAssigned: true
    }

    // Container configuration
    containers: [
      {
        name: 'photoalbum'
        image: webImageName
        resources: {
          cpu: json('0.5')
          memory: '1Gi'
        }
        env: [
          {
            name: 'ConnectionStrings__DefaultConnection'
            value: sqlConnectionString
          }
          {
            name: 'AzureStorageBlob__Endpoint'
            value: storageAccount.outputs.primaryBlobEndpoint
          }
          {
            name: 'AzureStorageBlob__ContainerName'
            value: 'photos'
          }
          {
            name: 'ASPNETCORE_ENVIRONMENT'
            value: 'Production'
          }
        ]
      }
    ]

    // Registry configuration - Only configure ACR if using a custom image (not the default hello-world)
    // During initial provision with hello-world image, this is empty (no ACR needed)
    // During deploy with actual app image, this configures ACR with managed identity
    registries: contains(webImageName, containerRegistry.outputs.loginServer) ? [
      {
        server: containerRegistry.outputs.loginServer
        identity: 'system'
      }
    ] : []

    // Ingress configuration
    ingressExternal: true
    ingressTargetPort: 8080

    // Scaling configuration
    scaleMinReplicas: 1
    scaleMaxReplicas: 3
  }
}

// === Role Assignments ===

// Grant AcrPull role to Container App managed identity
// This must complete before the Container App tries to pull images
module acrPullRoleAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'acr-pull-role-assignment'
  params: {
    principalId: containerApp.outputs.systemAssignedMIPrincipalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // AcrPull
    resourceId: containerRegistry.outputs.resourceId
    principalType: 'ServicePrincipal'
  }
}

// Grant Storage Blob Data Contributor to Container App managed identity
module storageBlobRoleAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'storage-blob-role-assignment'
  params: {
    principalId: containerApp.outputs.systemAssignedMIPrincipalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe') // Storage Blob Data Contributor
    resourceId: storageAccount.outputs.resourceId
    principalType: 'ServicePrincipal'
  }
}

// Configure Azure AD admin for SQL Server (using Container App managed identity)
// Note: Uses compile-time variable for SQL server name to avoid BCP120 error
resource sqlAdAdminConfig 'Microsoft.Sql/servers/administrators@2023-08-01-preview' = {
  name: '${sqlServerName}/ActiveDirectory'
  properties: {
    administratorType: 'ActiveDirectory'
    login: 'ContainerApp-${containerApp.outputs.name}'
    sid: containerApp.outputs.systemAssignedMIPrincipalId
    tenantId: tenant().tenantId
  }
  dependsOn: [
    sqlServer
  ]
}

// === Outputs ===
output AZURE_LOCATION string = location
output AZURE_RESOURCE_GROUP string = resourceGroup().name
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.name
output AZURE_CONTAINERAPP_NAME string = containerApp.outputs.name
output AZURE_CONTAINERAPP_FQDN string = containerApp.outputs.fqdn
output AZURE_CONTAINERAPP_URL string = 'https://${containerApp.outputs.fqdn}'
output AZURE_SQL_SERVER_NAME string = sqlServer.outputs.name
output AZURE_SQL_SERVER_FQDN string = sqlServerFqdn
output AZURE_SQL_DATABASE_NAME string = sqlDatabaseName
output AZURE_STORAGE_ACCOUNT_NAME string = storageAccount.outputs.name
output AZURE_STORAGE_BLOB_ENDPOINT string = storageAccount.outputs.primaryBlobEndpoint
