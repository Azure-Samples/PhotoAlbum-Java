param sqlServerName string
param principalId string
param adminLogin string

resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' existing = {
  name: sqlServerName
}

resource sqlAdAdmin 'Microsoft.Sql/servers/administrators@2023-05-01-preview' = {
  parent: sqlServer
  name: 'ActiveDirectory'
  properties: {
    administratorType: 'ActiveDirectory'
    login: adminLogin
    sid: principalId
    tenantId: subscription().tenantId
  }
}

output adminPrincipalId string = principalId
