@description('Required. Name of the solution.')
param name string

@description('Required. Name of the Log Analytics workspace where the solution will be deployed/enabled.')
param logAnalyticsWorkspaceName string

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Optional. The product of the deployed solution. For Microsoft published gallery solution it should be OMSGallery. This is case sensitive.')
param product string = 'OMSGallery'

@description('Optional. The publisher name of the deployed solution. For gallery solution, it is Microsoft.')
param publisher string = 'Microsoft'

@description('Optional. Enable telemetry via the Customer Usage Attribution ID (GUID).')
param enableDefaultTelemetry bool = true

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' existing = {
  name: logAnalyticsWorkspaceName
}

var solutionName = '${name}(${logAnalyticsWorkspace.name})'

resource defaultTelemetry 'Microsoft.Resources/deployments@2021-04-01' = if (enableDefaultTelemetry) {
  name: 'pid-47ed15a6-730a-4827-bcb4-0fd963ffbd82-${uniqueString(deployment().name, location)}'
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}

resource solution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: solutionName
  location: location
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
  }
  plan: {
    name: solutionName
    promotionCode: ''
    product: '${product}/${name}'
    publisher: publisher
  }
}

@description('The name of the deployed solution.')
output name string = solution.name

@description('The resource ID of the deployed solution.')
output resourceId string = solution.id

@description('The resource group where the solution is deployed.')
output resourceGroupName string = resourceGroup().name

@description('The location the resource was deployed into.')
output location string = solution.location
