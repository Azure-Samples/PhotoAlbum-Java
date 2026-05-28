// ============================================================
// PhotoAlbum-Java - Main Bicep Template (Subscription Scope)
// ============================================================
// Deploys: Resource Group + all Azure resources for PhotoAlbum-Java
// Region: centralus | Tool: Azure CLI
// ============================================================

targetScope = 'subscription'

@description('Environment name used for resource naming and tagging')
param environmentName string = 'photoalbum'

@description('Primary location for all Azure resources')
param location string = 'centralus'

@description('Name of the resource group to create')
param resourceGroupName string = 'photoalbum-rg'

@description('PostgreSQL flexible server administrator login username')
param postgresAdminUsername string = 'pgadmin'

@description('PostgreSQL flexible server administrator login password')
@secure()
param postgresAdminPassword string

// ===========================
// Resource Group
// ===========================
resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
  tags: {
    Environment: environmentName
    Application: 'PhotoAlbum'
    ManagedBy: 'Bicep'
  }
}

// ===========================
// All Resources (RG-scoped module)
// ===========================
module resources './modules/resources.bicep' = {
  name: 'photoalbum-resources-deployment'
  scope: rg
  params: {
    environmentName: environmentName
    location: location
    postgresAdminUsername: postgresAdminUsername
    postgresAdminPassword: postgresAdminPassword
  }
}

// ===========================
// Outputs
// ===========================
output containerAppName string = resources.outputs.containerAppName
output containerAppFqdn string = resources.outputs.containerAppFqdn
output containerAppEnvName string = resources.outputs.containerAppEnvName
output acrName string = resources.outputs.acrName
output acrLoginServer string = resources.outputs.acrLoginServer
output postgresServerName string = resources.outputs.postgresServerName
output managedIdentityClientId string = resources.outputs.managedIdentityClientId
output managedIdentityId string = resources.outputs.managedIdentityId
output managedIdentityName string = resources.outputs.managedIdentityName
output resourceGroupName string = rg.name
output subscriptionId string = subscription().subscriptionId
output location string = location
