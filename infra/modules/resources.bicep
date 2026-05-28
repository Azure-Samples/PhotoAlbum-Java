// ============================================================
// PhotoAlbum-Java - Resources Module (Resource Group Scope)
// ============================================================
// Creates all Azure resources needed by the PhotoAlbum-Java app:
//   - User-Assigned Managed Identity
//   - Log Analytics Workspace
//   - Azure Container Registry (+ AcrPull role assignment)
//   - Container Apps Environment
//   - PostgreSQL Flexible Server + Database + Firewall Rule
//   - Azure Container App
// ============================================================

@description('Environment name used for resource naming')
param environmentName string

@description('Location for all resources')
param location string

@description('PostgreSQL administrator login username')
param postgresAdminUsername string

@description('PostgreSQL administrator login password')
@secure()
param postgresAdminPassword string

// ===========================
// Resource Token (unique, alphanumeric)
// ===========================
var resourceToken = uniqueString(subscription().id, resourceGroup().id, location, environmentName)

// ===========================
// User-Assigned Managed Identity
// Must be created first – used by ACR role assignment and Container App
// ===========================
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'azumi${resourceToken}'
  location: location
  tags: {
    Environment: environmentName
    Application: 'PhotoAlbum'
  }
}

// ===========================
// Log Analytics Workspace
// Used by Container Apps Environment for log aggregation
// ===========================
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'azlaw${resourceToken}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
  tags: {
    Environment: environmentName
    Application: 'PhotoAlbum'
  }
}

// ===========================
// Azure Container Registry
// ===========================
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: 'azacr${resourceToken}'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
  }
  tags: {
    Environment: environmentName
    Application: 'PhotoAlbum'
  }
}

// AcrPull role assignment: managed identity → ACR
// MUST be defined BEFORE the Container App resource
var acrPullRoleDefinitionId = '7f951dda-4ed3-4680-a7ca-43fe172d538d'
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, managedIdentity.id, acrPullRoleDefinitionId)
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPullRoleDefinitionId)
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// ===========================
// Container Apps Environment
// Connected to Log Analytics Workspace
// ===========================
resource containerAppEnv 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: 'azace${resourceToken}'
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
  tags: {
    Environment: environmentName
    Application: 'PhotoAlbum'
  }
}

// ===========================
// PostgreSQL Flexible Server
// Version 17, Burstable B1ms, AAD + password auth enabled
// ===========================
resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2024-11-01-preview' = {
  name: 'azpgf${resourceToken}'
  location: location
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  properties: {
    version: '17'
    administratorLogin: postgresAdminUsername
    administratorLoginPassword: postgresAdminPassword
    storage: {
      storageSizeGB: 32
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
    authConfig: {
      activeDirectoryAuth: 'Enabled'
      passwordAuth: 'Enabled'
    }
  }
  tags: {
    Environment: environmentName
    Application: 'PhotoAlbum'
  }
}

// PostgreSQL Database (not named 'postgres' per rules)
resource postgresDatabase 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2024-11-01-preview' = {
  parent: postgresServer
  name: 'photoalbum'
  properties: {
    charset: 'UTF8'
    collation: 'en_US.UTF8'
  }
}

// Firewall Rule: Allow Azure Services (IP 0.0.0.0)
resource postgresFirewallAllowAzure 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2024-11-01-preview' = {
  parent: postgresServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// ===========================
// Azure Container App
// - User-assigned managed identity attached
// - Registry connection via managed identity (NOT admin password)
// - CORS enabled
// - Initial image: MCR hello-world (updated by deploy script)
// ===========================
resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'azca${resourceToken}'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
        transport: 'http'
        corsPolicy: {
          allowedOrigins: ['*']
          allowedMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH']
          allowedHeaders: ['*']
          allowCredentials: false
        }
      }
      registries: [
        {
          server: acr.properties.loginServer
          identity: managedIdentity.id
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'photo-album'
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: [
            {
              name: 'SPRING_PROFILES_ACTIVE'
              value: 'docker'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 3
      }
    }
  }
  tags: {
    Environment: environmentName
    Application: 'PhotoAlbum'
  }
  dependsOn: [
    acrPullRoleAssignment  // AcrPull must be assigned before container app is created
  ]
}

// ===========================
// Outputs
// ===========================
output containerAppName string = containerApp.name
output containerAppFqdn string = containerApp.properties.configuration.ingress.fqdn
output containerAppEnvName string = containerAppEnv.name
output acrName string = acr.name
output acrLoginServer string = acr.properties.loginServer
output postgresServerName string = postgresServer.name
output managedIdentityClientId string = managedIdentity.properties.clientId
output managedIdentityId string = managedIdentity.id
output managedIdentityName string = managedIdentity.name
output logAnalyticsName string = logAnalytics.name
