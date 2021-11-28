@description('Required. The name of the Azure Factory to create')
param name string

@description('Optional. The name of the Managed Virtual Network')
param managedVirtualNetworkName string = ''

@description('Optional. The object for the configuration of a Integration Runtime')
param integrationRuntime object = {}

@description('Optional. Location for all Resources.')
param location string = resourceGroup().location

@description('Optional. Enable or disable public network access.')
param publicNetworkAccess bool = true

@description('Optional. Boolean to define whether or not to configure git during template deployment.')
param gitConfigureLater bool = true

@description('Optional. Repository type - can be \'FactoryVSTSConfiguration\' or \'FactoryGitHubConfiguration\'. Default is \'FactoryVSTSConfiguration\'.')
param gitRepoType string = 'FactoryVSTSConfiguration'

@description('Optional. The account name.')
param gitAccountName string = ''

@description('Optional. The project name. Only relevant for \'FactoryVSTSConfiguration\'.')
param gitProjectName string = ''

@description('Optional. The repository name.')
param gitRepositoryName string = ''

@description('Optional. The collaboration branch name. Default is \'main\'.')
param gitCollaborationBranch string = 'main'

@description('Optional. The root folder path name. Default is \'/\'.')
param gitRootFolder string = '/'

@description('Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.')
@minValue(0)
@maxValue(365)
param diagnosticLogsRetentionInDays int = 365

@description('Optional. Resource ID of the diagnostic storage account.')
param diagnosticStorageAccountId string = ''

@description('Optional. Resource identifier of log analytics.')
param workspaceId string = ''

@allowed([
  'CanNotDelete'
  'NotSpecified'
  'ReadOnly'
])
@description('Optional. Specify the type of lock.')
param lock string = 'NotSpecified'

@description('Optional. The name of logs that will be streamed.')
@allowed([
  'ActivityRuns'
  'PipelineRuns'
  'TriggerRuns'
  'SSISPackageEventMessages'
  'SSISPackageExecutableStatistics'
  'SSISPackageEventMessageContext'
  'SSISPackageExecutionComponentPhases'
  'SSISPackageExecutionDataStatistics'
  'SSISIntegrationRuntimeLogs'
])
param logsToEnable array = [
  'ActivityRuns'
  'PipelineRuns'
  'TriggerRuns'
  'SSISPackageEventMessages'
  'SSISPackageExecutableStatistics'
  'SSISPackageEventMessageContext'
  'SSISPackageExecutionComponentPhases'
  'SSISPackageExecutionDataStatistics'
  'SSISIntegrationRuntimeLogs'
]

@description('Optional. The name of metrics that will be streamed.')
@allowed([
  'AllMetrics'
])
param metricsToEnable array = [
  'AllMetrics'
]

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

@description('Optional. Array of role assignment objects that contain the \'roleDefinitionIdOrName\' and \'principalId\' to define RBAC role assignments on this resource. In the roleDefinitionIdOrName attribute, you can provide either the display name of the role definition, or it\'s fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.')
param roleAssignments array = []

@description('Optional. Tags of the resource.')
param tags object = {}

@description('Optional. Customer Usage Attribution ID (GUID). This GUID must be previously registered')
param cuaId string = ''

module pid_cuaId '.bicep/nested_cuaId.bicep' = if (!empty(cuaId)) {
  name: 'pid-${cuaId}'
  params: {}
}

resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    repoConfiguration: bool(gitConfigureLater) ? null : json('{"type": "${gitRepoType}","accountName": "${gitAccountName}","repositoryName": "${gitRepositoryName}",${((gitRepoType == 'FactoryVSTSConfiguration') ? '"projectName": "${gitProjectName}",' : '')}"collaborationBranch": "${gitCollaborationBranch}","rootFolder": "${gitRootFolder}"}')
    publicNetworkAccess: bool(publicNetworkAccess) ? 'Enabled' : 'Disabled'
  }
}

module dataFactory_managedVirtualNetwork 'managedVirtualNetwork/deploy.bicep' = if (!empty(managedVirtualNetworkName)) {
  name: '${uniqueString(deployment().name, location)}-ManagedVirtualNetwork'
  params: {
    name: managedVirtualNetworkName
    dataFactoryName: dataFactory.name
  }
}

module dataFactory_integrationRuntime 'integrationRuntime/deploy.bicep' = if (!empty(integrationRuntime)) {
  name: '${uniqueString(deployment().name, location)}-IntegrationRuntime'
  params: {
    dataFactoryName: dataFactory.name
    name: integrationRuntime.name
    type: integrationRuntime.type
    managedVirtualNetworkName: contains(integrationRuntime, 'managedVirtualNetworkName') ? integrationRuntime.managedVirtualNetworkName : ''
    typeProperties: integrationRuntime.typeProperties
  }
  dependsOn: [
    dataFactory_managedVirtualNetwork
  ]
}

resource dataFactory_lock 'Microsoft.Authorization/locks@2016-09-01' = if (lock != 'NotSpecified') {
  name: '${dataFactory.name}-${lock}-lock'
  properties: {
    level: lock
    notes: (lock == 'CanNotDelete') ? 'Cannot delete resource or child resources.' : 'Cannot modify the resource or child resources.'
  }
  scope: dataFactory
}

resource dataFactory_diagnosticSettings 'Microsoft.Insights/diagnosticsettings@2017-05-01-preview' = if ((!empty(diagnosticStorageAccountId)) || (!empty(workspaceId))) {
  name: '${dataFactory.name}-diagnosticSettings'
  properties: {
    storageAccountId: empty(diagnosticStorageAccountId) ? null : diagnosticStorageAccountId
    workspaceId: empty(workspaceId) ? null : workspaceId
    metrics: (empty(diagnosticStorageAccountId) && empty(workspaceId)) ? null : diagnosticsMetrics
    logs: (empty(diagnosticStorageAccountId) && empty(workspaceId)) ? null : diagnosticsLogs
  }
  scope: dataFactory
}

module dataFactory_rbac '.bicep/nested_rbac.bicep' = [for (roleAssignment, index) in roleAssignments: {
  name: '${deployment().name}-rbac-${index}'
  params: {
    principalIds: roleAssignment.principalIds
    roleDefinitionIdOrName: roleAssignment.roleDefinitionIdOrName
    resourceId: dataFactory.id
  }
}]

@description('The Name of the Azure Data Factory instance.')
output dataFactoryName string = dataFactory.name

@description('The Resource ID of the Data factory.')
output dataFactoryResourceId string = dataFactory.id

@description('The name of the Resource Group with the Data factory.')
output dataFactoryResourceGroup string = resourceGroup().name
