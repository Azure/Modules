@description('Required. Name of the Web Application Portal Name')
param name string

@description('Optional. Location for all Resources.')
param location string = resourceGroup().location

@description('Optional. Resource Id of the existing ApplicationInsights. If set, ApplicationInsights will be configured for the resource.')
param appInsightsId string = ''

@description('Optional. If true, ApplicationInsights will be configured for the Function App.')
param enableMonitoring bool = true

@description('Required. Kind of resource to deploy')
@allowed([
  'functionapp'
  'app'
])
param kind string

// sites specific both kinds

@description('Optional. The Resource Id of the App Service Plan to use for the App. If not provided, the hosting plan name is used to create a new plan.')
param appServicePlanId string = ''

@description('Optional. The Resource Id of the App Service Environment to use for the Function App.')
param appServiceEnvironmentId string = ''


// functionApp

@description('Optional. The name of the storage account to managing triggers and logging function executions.')
param storageAccountName string = ''

@description('Optional. Resource group of the storage account to use. Required if the storage account is in a different resource group than the function app itself.')
param storageAccountResourceGroupName string = resourceGroup().name

@description('Optional. Runtime of the function worker.')
@allowed([
  'dotnet'
  'node'
  'python'
  'java'
  'powershell'
  ''
])
param functionsWorkerRuntime string = ''

@description('Optional. Version if the function extension.')
param functionsExtensionVersion string = '~3'


// @description('Optional. Required if no appServicePlanId is provided to deploy a new app service plan.')
// param appServicePlanName string = ''

// @description('Optional. The pricing tier for the hosting plan.')
// @allowed([
//   'F1'
//   'D1'
//   'B1'
//   'B2'
//   'B3'
//   'S1'
//   'S2'
//   'S3'
//   'P1'
//   'P1v2'
//   'P2'
//   'P3'
//   'P4'
// ])
// param appServicePlanSkuName string = 'F1'

// @description('Optional. Defines the number of workers from the worker pool that will be used by the app service plan')
// param appServicePlanWorkerSize int = 2

// @description('Optional. SkuTier of app service plan deployed if no appServicePlanId was provided.')
// param appServicePlanTier string = ''

// @description('Optional. SkuSize of app service plan deployed if no appServicePlanId was provided.')
// param appServicePlanSize string = ''

// @description('Optional. SkuFamily of app service plan deployed if no appServicePlanId was provided.')
// param appServicePlanFamily string = ''

// @description('Optional. SkuType of app service plan deployed if no appServicePlanId was provided.')
// @allowed([
//   'linux'
//   'windows'
// ])
// param appServicePlanType string = 'linux'





@description('Optional. Configures a web site to accept only https requests. Issues redirect for http requests.')
param httpsOnly bool = true

@description('Optional. If Client Affinity is enabled.')
param clientAffinityEnabled bool = true

@description('Required. Configuration of the app.')
param siteConfig object = {}

@description('Optional. The name of logs that will be streamed.')
@allowed([
  'AppServiceHTTPLogs'
  'AppServiceConsoleLogs'
  'AppServiceAppLogs'
  'AppServiceFileAuditLogs'
  'AppServiceAuditLogs'
])
param logsToEnable array = [
  'AppServiceHTTPLogs'
  'AppServiceConsoleLogs'
  'AppServiceAppLogs'
  'AppServiceFileAuditLogs'
  'AppServiceAuditLogs'
]

@description('Optional. The name of metrics that will be streamed.')
@allowed([
  'AllMetrics'
])
param metricsToEnable array = [
  'AllMetrics'
]

// Shared

@description('Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.')
@minValue(0)
@maxValue(365)
param diagnosticLogsRetentionInDays int = 365

@description('Optional. Resource identifier of the Diagnostic Storage Account.')
param diagnosticStorageAccountId string = ''

@description('Optional. Resource identifier of Log Analytics.')
param workspaceId string = ''

@description('Optional. Resource ID of the event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.')
param eventHubAuthorizationRuleId string = ''

@description('Optional. Name of the event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category.')
param eventHubName string = ''

@description('Optional. The type of identity used for the virtual machine. The type \'SystemAssigned, UserAssigned\' includes both an implicitly created identity and a set of user assigned identities. The type \'None\' (default) will remove any identities from the virtual machine.')
@allowed([
  'None'
  'SystemAssigned'
  'SystemAssigned, UserAssigned'
  'UserAssigned'
])
param managedServiceIdentity string = 'None'

@description('Optional. Mandatory if \'managedServiceIdentity\' contains UserAssigned. The list of user identities to assign to the resource.')
param userAssignedIdentities object = {}

@allowed([
  'CanNotDelete'
  'NotSpecified'
  'ReadOnly'
])
@description('Optional. Specify the type of lock.')
param lock string = 'NotSpecified'

@description('Optional. Configuration Details for private endpoints.')
param privateEndpoints array = []

@description('Optional. Tags of the resource.')
param tags object = {}

@description('Optional. Customer Usage Attribution id (GUID). This GUID must be previously registered')
param cuaId string = ''

@description('Optional. Array of role assignment objects that contain the \'roleDefinitionIdOrName\' and \'principalId\' to define RBAC role assignments on this resource. In the roleDefinitionIdOrName attribute, you can provide either the display name of the role definition, or its fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'')
param roleAssignments array = []

// Vars

var diagnosticsLogs = [for log in logsToEnable: {
  category: log
  enabled: true
  retentionPolicy: {
    enabled: true
    days: diagnosticLogsRetentionInDays
  }
}]

var diagnosticsMetrics = [for metric in metricsToEnable: {
  category: metric
  timeGrain: null
  enabled: true
  retentionPolicy: {
    enabled: true
    days: diagnosticLogsRetentionInDays
  }
}]

var hostingEnvironment = {
  id: appServiceEnvironmentId
}

// resources
module pid_cuaId '.bicep/nested_cuaId.bicep' = if (!empty(cuaId)) {
  name: 'pid-${cuaId}'
  params: {}
}

// resource appServicePlan 'Microsoft.Web/serverfarms@2021-02-01' = if (empty(appServicePlanId)) {
//   name: !empty(appServicePlanName) ? appServicePlanName : 'dummyAppServicePlanName'
//   kind: appServicePlanType
//   location: location
//   tags: tags
//   sku: {
//     name: appServicePlanSkuName
//     capacity: appServicePlanWorkerSize
//     tier: appServicePlanTier
//     size: appServicePlanSize
//     family: appServicePlanFamily
//   }
//   properties: {
//     hostingEnvironmentProfile: !empty(appServiceEnvironmentId) ? json('{ id: ${hostingEnvironment} }') : null
//   }
// }

// resource appServicePlan_lock 'Microsoft.Authorization/locks@2016-09-01' = if (lock != 'NotSpecified' && empty(appServicePlanId)) {
//   name: '${appServicePlan.name}-${lock}-lock'
//   properties: {
//     level: lock
//     notes: lock == 'CanNotDelete' ? 'Cannot delete resource or child resources.' : 'Cannot modify the resource or child resources.'
//   }
//   scope: appServicePlan
// }

resource appServicePlan 'Microsoft.Web/serverfarms@2021-02-01' existing = if (!empty(appServicePlanId)) {
  name: last(split(appServicePlanId, '/'))
  scope: resourceGroup(split(appServicePlanId, '/')[2], split(appServicePlanId, '/')[4])
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = if (!empty(appInsightsId)) {
  name: last(split(appInsightsId, '/'))
  scope: resourceGroup(split(appInsightsId, '/')[2], split(appInsightsId, '/')[4])
}

// resource virtualMachine_logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = if (!empty(workspaceId)) {
//   name: last(split(workspaceId, '/'))
//   scope: resourceGroup(split(workspaceId, '/')[2], split(workspaceId, '/')[4])
// }

resource app 'Microsoft.Web/sites@2020-12-01' = {
  name: name
  location: location
  kind: kind
  tags: tags
  identity: {
    type: managedServiceIdentity
    userAssignedIdentities: !empty(userAssignedIdentities) ? userAssignedIdentities : null
  }
  properties: {
    // serverFarmId: !empty(appServicePlanId) ? appServicePlanId : appServicePlan.id
    serverFarmId: appServicePlan.id
    httpsOnly: httpsOnly
    hostingEnvironmentProfile: !empty(appServiceEnvironmentId) ? json('{ id: ${hostingEnvironment} }') : null
    clientAffinityEnabled: clientAffinityEnabled
    siteConfig: siteConfig
  }


}

// resource app_insights 'microsoft.insights/components@2020-02-02' = if (enableMonitoring) {
//   name: app.name
//   location: location
//   kind: 'web'
//   tags: tags
//   properties: {
//     Application_Type: 'web'
//     Request_Source: 'rest'
//   }
// }

module app_insights '.bicep/nested_components.bicep' = if (enableMonitoring) {
  name: '${uniqueString(deployment().name, location)}-AppService-InsightsComponent'
  params: {
    name: app.name
    location: location
    kind: 'web'
    tags: tags
    appInsightsWorkspaceResourceId: workspaceId
    appInsightsType: 'web'
    appInsightsRequestSource: 'rest'
  }
}

// resource app_appsettings 'config@2019-08-01' = {
//     name: 'appsettings'
//     properties: {
//       // AzureWebJobsStorage: !empty(storageAccountName) ? 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listkeys(resourceId(subscription().subscriptionId, storageAccountResourceGroupName, 'Microsoft.Storage/storageAccounts', storageAccountName), '2019-06-01').keys[0].value};' : any(null)
//       // AzureWebJobsDashboard: !empty(storageAccountName) ? 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listkeys(resourceId(subscription().subscriptionId, storageAccountResourceGroupName, 'Microsoft.Storage/storageAccounts', storageAccountName), '2019-06-01').keys[0].value};' : any(null)
//       // FUNCTIONS_EXTENSION_VERSION: appServicePlanType == 'functionApp' && !empty(functionsExtensionVersion) ? functionsExtensionVersion : any(null)
//       // FUNCTIONS_WORKER_RUNTIME: appServicePlanType == 'functionApp' && !empty(functionsWorkerRuntime) ? functionsWorkerRuntime : any(null)
//       // APPINSIGHTS_INSTRUMENTATIONKEY: enableMonitoring ? reference('microsoft.insights/components/${name}', '2015-05-01').InstrumentationKey : null
//       // APPLICATIONINSIGHTS_CONNECTION_STRING: enableMonitoring ? reference('microsoft.insights/components/${name}', '2015-05-01').ConnectionString : null
//       APPINSIGHTS_INSTRUMENTATIONKEY: !empty(appInsightsId) ? appInsights.properties.InstrumentationKey : ''
//       APPLICATIONINSIGHTS_CONNECTION_STRING: !empty(appInsightsId) ? appInsights.properties.ConnectionString : ''
//     }
//   }

resource app_lock 'Microsoft.Authorization/locks@2016-09-01' = if (lock != 'NotSpecified') {
  name: '${uniqueString(deployment().name, location)}-AppService-${lock}-Lock'
  properties: {
    level: lock
    notes: lock == 'CanNotDelete' ? 'Cannot delete resource or child resources.' : 'Cannot modify the resource or child resources.'
  }
  scope: app
}

resource app_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = if (!empty(diagnosticStorageAccountId) || !empty(workspaceId) || !empty(eventHubAuthorizationRuleId) || !empty(eventHubName)) {
  name: '${uniqueString(deployment().name, location)}-AppService-DiagnosticSettings'
  properties: {
    storageAccountId: empty(diagnosticStorageAccountId) ? null : diagnosticStorageAccountId
    workspaceId: empty(workspaceId) ? null : workspaceId
    eventHubAuthorizationRuleId: empty(eventHubAuthorizationRuleId) ? null : eventHubAuthorizationRuleId
    eventHubName: empty(eventHubName) ? null : eventHubName
    metrics: empty(diagnosticStorageAccountId) && empty(workspaceId) && empty(eventHubAuthorizationRuleId) && empty(eventHubName) ? null : diagnosticsMetrics
    logs: empty(diagnosticStorageAccountId) && empty(workspaceId) && empty(eventHubAuthorizationRuleId) && empty(eventHubName) ? null : diagnosticsLogs
  }
  scope: app
}

module app_privateEndpoint '.bicep/nested_privateEndpoint.bicep' = [for (privateEndpoint, index) in privateEndpoints: {
  name: '${uniqueString(deployment().name, location)}-AppService-PrivateEndpoints-${index}'
  params: {
    privateEndpointResourceId: app.id
    privateEndpointVnetLocation: reference(split(privateEndpoint.subnetResourceId, '/subnets/')[0], '2020-06-01', 'Full').location
    privateEndpointObj: privateEndpoint
    tags: tags
  }
}]

module app_rbac '.bicep/nested_rbac.bicep' = [for (roleAssignment, index) in roleAssignments: {
  name: '${uniqueString(deployment().name, location)}-AppService-Rbac-${index}'
  params: {
    roleAssignmentObj: roleAssignment
    resourceName: app.name
  }
}]

@description('The name of the site')
output siteName string = app.name

@description('The resourceId of the site')
output siteResourceId string = app.id

@description('The resource group the site was deployed into')
output siteResourceGroup string = resourceGroup().name
