@description('Required. The name of the parent SQL Server.')
param serverName string

@description('Required. The name of the parent database.')
param databaseName string

@description('Optional. Monthly retention in ISO 8601 duration format.')
param weeklyRetention string = ''

@description('Optional. Weekly retention in ISO 8601 duration format.')
param monthlyRetention string = ''

@description('Optional. Week of year backup to keep for yearly retention.')
param weekOfYear int = 1

@description('Optional. Yearly retention in ISO 8601 duration format.')
param yearlyRetention string = ''

resource server 'Microsoft.Sql/servers@2022-05-01-preview' existing = {
  name: serverName
}

resource database 'Microsoft.Sql/servers/databases@2022-05-01-preview' existing = {
  name: databaseName
  parent: server
}

resource backupLongTermRetentionPolicy 'Microsoft.Sql/servers/databases/backupLongTermRetentionPolicies@2022-05-01-preview' = {
  name: 'default'
  parent: database
  properties: {
    monthlyRetention: monthlyRetention
    weeklyRetention: weeklyRetention
    weekOfYear: weekOfYear
    yearlyRetention: yearlyRetention
  }
}

@description('The resource group of the deployed azure sql backup policy.')
output resourceGroupName string = resourceGroup().name
