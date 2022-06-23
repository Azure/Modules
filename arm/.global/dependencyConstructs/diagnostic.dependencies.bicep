// ========== //
// Parameters //
// ========== //

@description('Required. The name of the storage account to create')
param storageAccountName string

@description('Required. The name of the log analytics workspace to create')
param logAnalyticsWorkspaceName string

@description('Required. The name of the event hub namespace to be created')
param eventHubNamespaceName string

@description('Required. The name of the event hub to be created inside the event hub namespace')
param eventHubNamespaceEventHubName string

@description('Optional. The location to deploy to')
param location string = resourceGroup().location

// =========== //
// Deployments //
// =========== //
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    allowBlobPublicAccess: false
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: logAnalyticsWorkspaceName
  location: location
}

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2021-11-01' = {
  name: eventHubNamespaceName
  location: location

  resource eventHub 'eventhubs@2021-11-01' = {
    name: eventHubNamespaceEventHubName
  }

  resource authorizationRule 'authorizationRules@2021-06-01-preview' = {
    name: 'RootManageSharedAccessKey'
    properties: {
      rights: [
        'Listen'
        'Manage'
        'Send'
      ]
    }
  }
}

// ======= //
// Outputs //
// ======= //
output storageAccountResourceId string = storageAccount.id
output logAnalyticsWorkspaceResourceId string = logAnalyticsWorkspace.id
output eventHubNamespaceResourceId string = eventHubNamespace.id
output eventHubAuthorizationRuleId string = eventHubNamespace::authorizationRule.id
output eventHubNamespaceEventHubName string = eventHubNamespace::eventHub.name
