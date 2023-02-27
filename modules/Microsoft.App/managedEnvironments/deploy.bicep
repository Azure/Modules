@description('Required. Name of the Container Apps Managed Environment.')
param name string

@description('Required. Existing Log Analytics Workspace name.')
param logAnalticsWorkspaceName string

@description('Required. Existing resource group name of the Log Analytics Workspace .')
param resourceGroupLAWorkspace string

@description('Optional. Location for all Resources.')
param location string = resourceGroup().location

@description('Optional. Resource tags.')
param tags object = {}

@description('Optional. Array of role assignment objects that contain the \'roleDefinitionIdOrName\' and \'principalId\' to define RBAC role assignments on this resource. In the roleDefinitionIdOrName attribute, you can provide either the display name of the role definition, or its fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.')
param roleAssignments array = []

@allowed([
  'Consumption'
  'Premium'
])
@description('Optional. Managed environment Sku.')
param skuName string = 'Consumption'

@description('Optional. Logs destination.')
param logsDestination string = 'log-analytics'

@description('Optional. Enable telemetry via a Globally Unique Identifier (GUID).')
param enableDefaultTelemetry bool

@description('Optional. Application Insights connection string used by Dapr to export Service to Service communication telemetry.')
@secure()
param daprAIConnectionString string = ''

@description('Optional. Azure Monitor instrumentation key used by Dapr to export Service to Service communication telemetry.')
@secure()
param daprAIInstrumentationKey string = ''

@description('Optional. CIDR notation IP range assigned to the Docker bridge, network. Must not overlap with any other provided IP ranges.')
param dockerBridgeCidr string = ''

@description('Optional. Resource ID of a subnet for infrastructure components. This subnet must be in the same VNET as the subnet defined in runtimeSubnetId. Must not overlap with any other provided IP ranges.')
param infrastructureSubnetId string = ''

@description('Optional. Boolean indicating the environment only has an internal load balancer. These environments do not have a public static IP resource. They must provide runtimeSubnetId and infrastructureSubnetId if enabling this property.')
param internal bool = false

@description('Optional. Configuration used to control the Environment Egress outbound traffic.')
param vnetOutboundSettings object = {}

@description('Optional. IP range in CIDR notation that can be reserved for environment infrastructure IP addresses. Must not overlap with any other provided IP ranges.')
param platformReservedCidr string = ''

@description('Optional. An IP address from the IP range defined by platformReservedCidr that will be reserved for the internal DNS server.')
param platformReservedDnsIP string = ''

@description('Optional. Resource ID of a subnet that Container App containers are injected into. This subnet must be in the same VNET as the subnet defined in infrastructureSubnetId. Must not overlap with any other provided IP ranges.')
param runtimeSubnetId string = ''

@description('Optional. Whether or not this Managed Environment is zone-redundant.')
param zoneRedundant bool = false

@description('Optional. Certificate password.')
@secure()
param certificatePassword string = ''

@description('Optional. Certificate value for this.')
@secure()
param certificateValue string = ''

@description('Optional. Dns suffix for the environment domain.')
param dnsSuffix string = ''

resource defaultTelemetry 'Microsoft.Resources/deployments@2022-09-01' = if (enableDefaultTelemetry) {
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

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalticsWorkspaceName
  scope: resourceGroup('${resourceGroupLAWorkspace}')
}

resource managedEnvironment 'Microsoft.App/managedEnvironments@2022-06-01-preview' = {
  name: name
  location: location
  tags: !empty(tags) ? tags : null
  sku: {
    name: skuName
  }
  properties: {
    appLogsConfiguration: {
      destination: logsDestination
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
    daprAIConnectionString: daprAIConnectionString
    daprAIInstrumentationKey: daprAIInstrumentationKey
    customDomainConfiguration: {
      certificatePassword: certificatePassword
      certificateValue: !empty(certificateValue) ? certificateValue : null
      dnsSuffix: dnsSuffix
    }
    vnetConfiguration: {
      dockerBridgeCidr: dockerBridgeCidr
      infrastructureSubnetId: infrastructureSubnetId
      internal: internal
      outboundSettings: !empty(vnetOutboundSettings) ? vnetOutboundSettings : null
      platformReservedCidr: platformReservedCidr
      platformReservedDnsIP: platformReservedDnsIP
      runtimeSubnetId: runtimeSubnetId
    }
    zoneRedundant: zoneRedundant
  }
}

module managedEnvironment_roleAssignments '.bicep/nested_roleAssignments.bicep' = [for (roleAssignment, index) in roleAssignments: {
  name: '${uniqueString(deployment().name, location)}-ManagedEnvironment-Rbac-${index}'
  params: {
    description: contains(roleAssignment, 'description') ? roleAssignment.description : ''
    principalIds: roleAssignment.principalIds
    principalType: contains(roleAssignment, 'principalType') ? roleAssignment.principalType : ''
    roleDefinitionIdOrName: roleAssignment.roleDefinitionIdOrName
    condition: contains(roleAssignment, 'condition') ? roleAssignment.condition : ''
    delegatedManagedIdentityResourceId: contains(roleAssignment, 'delegatedManagedIdentityResourceId') ? roleAssignment.delegatedManagedIdentityResourceId : ''
    resourceId: managedEnvironment.id
  }
}]

@description('The name of the resource group the Container Apps Managed Environment was deployed into.')
output resourceGroupName string = resourceGroup().name

@description('The location the resource was deployed into.')
output location string = managedEnvironment.location

@description('Managed Envrionment Name.')
output name string = managedEnvironment.name

@description('Managed environment ID.')
output resourceId string = managedEnvironment.id

@description('The name of the Log analytics workspace name.')
output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.name