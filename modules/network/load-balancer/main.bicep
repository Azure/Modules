metadata name = 'Load Balancers'
metadata description = 'This module deploys a Load Balancer.'
metadata owner = 'Azure/module-maintainers'

@description('Required. The Proximity Placement Groups Name.')
param name string

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Optional. Name of a load balancer SKU.')
@allowed([
  'Basic'
  'Standard'
])
param skuName string = 'Standard'

@description('Required. Array of objects containing all frontend IP configurations.')
@minLength(1)
param frontendIPConfigurations array

@description('Optional. Collection of backend address pools used by a load balancer.')
param backendAddressPools array = []

@description('Optional. Array of objects containing all load balancing rules.')
param loadBalancingRules array = []

@description('Optional. Array of objects containing all probes, these are references in the load balancing rules.')
param probes array = []

@description('Optional. Resource ID of the diagnostic storage account.')
param diagnosticStorageAccountId string = ''

@description('Optional. Resource ID of the diagnostic log analytics workspace.')
param diagnosticWorkspaceId string = ''

@description('Optional. Resource ID of the diagnostic event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.')
param diagnosticEventHubAuthorizationRuleId string = ''

@description('Optional. Name of the diagnostic event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category.')
param diagnosticEventHubName string = ''

@description('Optional. The lock settings of the service.')
param lock lockType

@description('Optional. Array of role assignment objects that contain the \'roleDefinitionIdOrName\' and \'principalId\' to define RBAC role assignments on this resource. In the roleDefinitionIdOrName attribute, you can provide either the display name of the role definition, or its fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.')
param roleAssignments roleAssignmentType

@description('Optional. Tags of the resource.')
param tags object = {}

@description('Optional. Enable telemetry via a Globally Unique Identifier (GUID).')
param enableDefaultTelemetry bool = true

@description('Optional. Collection of inbound NAT Rules used by a load balancer. Defining inbound NAT rules on your load balancer is mutually exclusive with defining an inbound NAT pool. Inbound NAT pools are referenced from virtual machine scale sets. NICs that are associated with individual virtual machines cannot reference an Inbound NAT pool. They have to reference individual inbound NAT rules.')
param inboundNatRules array = []

@description('Optional. The outbound rules.')
param outboundRules array = []

var frontendIPConfigurationsVar = [for (frontendIPConfiguration, index) in frontendIPConfigurations: {
  name: frontendIPConfiguration.name
  properties: {
    subnet: contains(frontendIPConfiguration, 'subnetId') && !empty(frontendIPConfiguration.subnetId) ? {
      id: frontendIPConfiguration.subnetId
    } : null
    publicIPAddress: contains(frontendIPConfiguration, 'publicIPAddressId') && !empty(frontendIPConfiguration.publicIPAddressId) ? {
      id: frontendIPConfiguration.publicIPAddressId
    } : null
    privateIPAddress: contains(frontendIPConfiguration, 'privateIPAddress') && !empty(frontendIPConfiguration.privateIPAddress) ? frontendIPConfiguration.privateIPAddress : null
    privateIPAddressVersion: contains(frontendIPConfiguration, 'privateIPAddressVersion') ? frontendIPConfiguration.privateIPAddressVersion : 'IPv4'
    privateIPAllocationMethod: contains(frontendIPConfiguration, 'subnetId') && !empty(frontendIPConfiguration.subnetId) ? (contains(frontendIPConfiguration, 'privateIPAddress') ? 'Static' : 'Dynamic') : null
    gatewayLoadBalancer: contains(frontendIPConfiguration, 'gatewayLoadBalancer') && !empty(frontendIPConfiguration.gatewayLoadBalancer) ? {
      id: frontendIPConfiguration.gatewayLoadBalancer
    } : null
    publicIPPrefix: contains(frontendIPConfiguration, 'publicIPPrefix') && !empty(frontendIPConfiguration.publicIPPrefix) ? {
      id: frontendIPConfiguration.publicIPPrefix
    } : null
  }
}]

var loadBalancingRulesVar = [for loadBalancingRule in loadBalancingRules: {
  name: loadBalancingRule.name
  properties: {
    backendAddressPool: {
      id: az.resourceId('Microsoft.Network/loadBalancers/backendAddressPools', name, loadBalancingRule.backendAddressPoolName)
    }
    backendPort: loadBalancingRule.backendPort
    disableOutboundSnat: contains(loadBalancingRule, 'disableOutboundSnat') ? loadBalancingRule.disableOutboundSnat : true
    enableFloatingIP: contains(loadBalancingRule, 'enableFloatingIP') ? loadBalancingRule.enableFloatingIP : false
    enableTcpReset: contains(loadBalancingRule, 'enableTcpReset') ? loadBalancingRule.enableTcpReset : false
    frontendIPConfiguration: {
      id: az.resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', name, loadBalancingRule.frontendIPConfigurationName)
    }
    frontendPort: loadBalancingRule.frontendPort
    idleTimeoutInMinutes: contains(loadBalancingRule, 'idleTimeoutInMinutes') ? loadBalancingRule.idleTimeoutInMinutes : 4
    loadDistribution: contains(loadBalancingRule, 'loadDistribution') ? loadBalancingRule.loadDistribution : 'Default'
    probe: {
      id: '${az.resourceId('Microsoft.Network/loadBalancers', name)}/probes/${loadBalancingRule.probeName}'
    }
    protocol: contains(loadBalancingRule, 'protocol') ? loadBalancingRule.protocol : 'Tcp'
  }
}]

var outboundRulesVar = [for outboundRule in outboundRules: {
  name: outboundRule.name
  properties: {
    frontendIPConfigurations: [
      {
        id: az.resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', name, outboundRule.frontendIPConfigurationName)
      }
    ]
    backendAddressPool: {
      id: az.resourceId('Microsoft.Network/loadBalancers/backendAddressPools', name, outboundRule.backendAddressPoolName)
    }
    protocol: contains(outboundRule, 'protocol') ? outboundRule.protocol : 'All'
    allocatedOutboundPorts: contains(outboundRule, 'allocatedOutboundPorts') ? outboundRule.allocatedOutboundPorts : 63984
    enableTcpReset: contains(outboundRule, 'enableTcpReset') ? outboundRule.enableTcpReset : true
    idleTimeoutInMinutes: contains(outboundRule, 'idleTimeoutInMinutes') ? outboundRule.idleTimeoutInMinutes : 4
  }
}]

var probesVar = [for probe in probes: {
  name: probe.name
  properties: {
    protocol: contains(probe, 'protocol') ? probe.protocol : 'Tcp'
    requestPath: toLower(probe.protocol) != 'tcp' ? probe.requestPath : null
    port: contains(probe, 'port') ? probe.port : 80
    intervalInSeconds: contains(probe, 'intervalInSeconds') ? probe.intervalInSeconds : 5
    numberOfProbes: contains(probe, 'numberOfProbes') ? probe.numberOfProbes : 2
  }
}]

var backendAddressPoolNames = [for backendAddressPool in backendAddressPools: {
  name: backendAddressPool.name
}]

@description('Optional. The name of metrics that will be streamed.')
@allowed([
  'AllMetrics'
])
param diagnosticMetricsToEnable array = [
  'AllMetrics'
]

@description('Optional. The name of the diagnostic setting, if deployed. If left empty, it defaults to "<resourceName>-diagnosticSettings".')
param diagnosticSettingsName string = ''

var enableReferencedModulesTelemetry = false

var diagnosticsMetrics = [for metric in diagnosticMetricsToEnable: {
  category: metric
  timeGrain: null
  enabled: true
}]

var builtInRoleNames = {
  'Avere Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4f8fab4f-1852-4a58-a46a-8eaf358af14a')
  'Avere Operator': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'c025889f-8102-4ebf-b32c-fc0c6f0c6bd9')
  'Azure Center for SAP solutions administrator': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7b0c7e81-271f-4c71-90bf-e30bdfdbc2f7')
  'Azure Center for SAP solutions reader': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '05352d14-a920-4328-a0de-4cbe7430e26b')
  'Azure Center for SAP solutions service role': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'aabbc5dd-1af0-458b-a942-81af88f9c138')
  'Azure Kubernetes Service Policy Add-on Deployment': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '18ed5180-3e48-46fd-8541-4ea054d57064')
  'Backup Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '5e467623-bb1f-42f4-a55d-6e525e11384b')
  'Backup Operator': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '00c29273-979b-4161-815c-10b084fb9324')
  Contributor: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  'Cosmos DB Operator': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '230815da-be43-4aae-9cb4-875f7bd000aa')
  'Desktop Virtualization Virtual Machine Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a959dbd1-f747-45e3-8ba6-dd80f235f97c')
  'DevTest Labs User': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '76283e04-6283-4c54-8f91-bcf1374a3c64')
  'DNS Resolver Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '0f2ebee7-ffd4-4fc0-b3b7-664099fdad5d')
  'DNS Zone Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'befefa01-2a29-4197-83a8-272ff33ce314')
  'DocumentDB Account Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '5bd9cd88-fe45-4216-938b-f97437e15450')
  'Domain Services Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'eeaeda52-9324-47f6-8069-5d5bade478b2')
  'Domain Services Reader': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '361898ef-9ed1-48c2-849c-a832951106bb')
  'LocalNGFirewallAdministrator role': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a8835c7d-b5cb-47fa-b6f0-65ea10ce07a2')
  'Log Analytics Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '92aaf0da-9dab-42b6-94a3-d43ce8d16293')
  'Log Analytics Reader': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '73c42c96-874c-492b-b04d-ab87d138a893')
  'Managed Application Contributor Role': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '641177b8-a67a-45b9-a033-47bc880bb21e')
  'Managed Application Operator Role': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'c7393b34-138c-406f-901b-d8cf2b17e6ae')
  'Managed Applications Reader': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b9331d33-8a36-4f8c-b097-4f54124fdb44')
  'Monitoring Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '749f88d5-cbae-40b8-bcfc-e573ddc772fa')
  'Monitoring Reader': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '43d0d8ad-25c7-4714-9337-8ba259a9fe05')
  'Network Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4d97b98b-1d4f-4787-a291-c67834d212e7')
  Owner: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')
  'Private DNS Zone Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b12aa53e-6015-4669-85d0-8515ebb3ae7f')
  Reader: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
  'Resource Policy Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '36243c78-bf99-498c-9df9-86d9f8d28608')
  'Role Based Access Control Administrator (Preview)': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'f58310d9-a9f6-439a-9e8d-f62e7b41a168')
  'Site Recovery Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '6670b86e-a3f7-4917-ac9b-5d6ab1be4567')
  'Site Recovery Operator': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '494ae006-db33-4328-bf46-533a6560a3ca')
  'SQL Managed Instance Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4939a1f6-9ae0-4e48-a1e0-f2cbe897382d')
  'SQL Security Manager': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '056cd41c-7e88-42e1-933e-88ba6a50c9c3')
  'Storage Account Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '17d1049b-9a84-46fb-8f53-869881c3d3ab')
  'Traffic Manager Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a4b10055-b0c7-44c2-b00f-c7b5b3550cf7')
  'User Access Administrator': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9')
  'Virtual Machine Administrator Login': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '1c0163c0-47e6-4577-8991-ea5c82e286e4')
  'Virtual Machine Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '9980e02c-c2be-4d73-94e8-173b1dc7cf3c')
  'Virtual Machine User Login': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'fb879df8-f326-4884-b1cf-06f3ad86be52')
  'Windows Admin Center Administrator Login': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a6333a3e-0164-44c3-b281-7a577aff287f')
}

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

resource loadBalancer 'Microsoft.Network/loadBalancers@2023-04-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  properties: {
    frontendIPConfigurations: frontendIPConfigurationsVar
    loadBalancingRules: loadBalancingRulesVar
    backendAddressPools: backendAddressPoolNames
    outboundRules: outboundRulesVar
    probes: probesVar
  }
}

module loadBalancer_backendAddressPools 'backend-address-pool/main.bicep' = [for (backendAddressPool, index) in backendAddressPools: {
  name: '${uniqueString(deployment().name, location)}-loadBalancer-backendAddressPools-${index}'
  params: {
    loadBalancerName: loadBalancer.name
    name: backendAddressPool.name
    tunnelInterfaces: contains(backendAddressPool, 'tunnelInterfaces') && !empty(backendAddressPool.tunnelInterfaces) ? backendAddressPool.tunnelInterfaces : []
    loadBalancerBackendAddresses: contains(backendAddressPool, 'loadBalancerBackendAddresses') && !empty(backendAddressPool.loadBalancerBackendAddresses) ? backendAddressPool.loadBalancerBackendAddresses : []
    drainPeriodInSeconds: contains(backendAddressPool, 'drainPeriodInSeconds') ? backendAddressPool.drainPeriodInSeconds : 0
    enableDefaultTelemetry: enableReferencedModulesTelemetry
  }
}]

module loadBalancer_inboundNATRules 'inbound-nat-rule/main.bicep' = [for (inboundNATRule, index) in inboundNatRules: {
  name: '${uniqueString(deployment().name, location)}-LoadBalancer-inboundNatRules-${index}'
  params: {
    loadBalancerName: loadBalancer.name
    name: inboundNATRule.name
    frontendIPConfigurationName: inboundNATRule.frontendIPConfigurationName
    frontendPort: inboundNATRule.frontendPort
    backendPort: contains(inboundNATRule, 'backendPort') ? inboundNATRule.backendPort : inboundNATRule.frontendPort
    backendAddressPoolName: contains(inboundNATRule, 'backendAddressPoolName') ? inboundNATRule.backendAddressPoolName : ''
    enableFloatingIP: contains(inboundNATRule, 'enableFloatingIP') ? inboundNATRule.enableFloatingIP : false
    enableTcpReset: contains(inboundNATRule, 'enableTcpReset') ? inboundNATRule.enableTcpReset : false
    frontendPortRangeEnd: contains(inboundNATRule, 'frontendPortRangeEnd') ? inboundNATRule.frontendPortRangeEnd : -1
    frontendPortRangeStart: contains(inboundNATRule, 'frontendPortRangeStart') ? inboundNATRule.frontendPortRangeStart : -1
    idleTimeoutInMinutes: contains(inboundNATRule, 'idleTimeoutInMinutes') ? inboundNATRule.idleTimeoutInMinutes : 4
    protocol: contains(inboundNATRule, 'protocol') ? inboundNATRule.protocol : 'Tcp'
    enableDefaultTelemetry: enableReferencedModulesTelemetry
  }
  dependsOn: [
    loadBalancer_backendAddressPools
  ]
}]

resource loadBalancer_lock 'Microsoft.Authorization/locks@2020-05-01' = if (!empty(lock ?? {}) && lock.?kind != 'None') {
  name: lock.?name ?? 'lock-${name}'
  properties: {
    level: lock.?kind ?? ''
    notes: lock.?kind == 'CanNotDelete' ? 'Cannot delete resource or child resources.' : 'Cannot delete or modify the resource or child resources.'
  }
  scope: loadBalancer
}

resource loadBalancer_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(diagnosticStorageAccountId) || !empty(diagnosticWorkspaceId) || !empty(diagnosticEventHubAuthorizationRuleId) || !empty(diagnosticEventHubName)) {
  name: !empty(diagnosticSettingsName) ? diagnosticSettingsName : '${name}-diagnosticSettings'
  properties: {
    storageAccountId: !empty(diagnosticStorageAccountId) ? diagnosticStorageAccountId : null
    workspaceId: !empty(diagnosticWorkspaceId) ? diagnosticWorkspaceId : null
    eventHubAuthorizationRuleId: !empty(diagnosticEventHubAuthorizationRuleId) ? diagnosticEventHubAuthorizationRuleId : null
    eventHubName: !empty(diagnosticEventHubName) ? diagnosticEventHubName : null
    metrics: diagnosticsMetrics
  }
  scope: loadBalancer
}

resource loadBalancer_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for (roleAssignment, index) in (roleAssignments ?? []): {
  name: guid(loadBalancer.id, roleAssignment.principalId, roleAssignment.roleDefinitionIdOrName)
  properties: {
    roleDefinitionId: contains(builtInRoleNames, roleAssignment.roleDefinitionIdOrName) ? builtInRoleNames[roleAssignment.roleDefinitionIdOrName] : roleAssignment.roleDefinitionIdOrName
    principalId: roleAssignment.principalId
    description: roleAssignment.?description
    principalType: roleAssignment.?principalType
    condition: roleAssignment.?condition
    conditionVersion: !empty(roleAssignment.?condition) ? (roleAssignment.?conditionVersion ?? '2.0') : null // Must only be set if condtion is set
    delegatedManagedIdentityResourceId: roleAssignment.?delegatedManagedIdentityResourceId
  }
  scope: loadBalancer
}]

@description('The name of the load balancer.')
output name string = loadBalancer.name

@description('The resource ID of the load balancer.')
output resourceId string = loadBalancer.id

@description('The resource group the load balancer was deployed into.')
output resourceGroupName string = resourceGroup().name

@description('The backend address pools available in the load balancer.')
output backendpools array = loadBalancer.properties.backendAddressPools

@description('The location the resource was deployed into.')
output location string = loadBalancer.location

// =============== //
//   Definitions   //
// =============== //

type lockType = {
  @description('Optional. Specify the name of lock.')
  name: string?

  @description('Optional. Specify the type of lock.')
  kind: ('CanNotDelete' | 'ReadOnly' | 'None')?
}?

type roleAssignmentType = {
  @description('Required. The name of the role to assign. If it cannot be found you can specify the role definition ID instead.')
  roleDefinitionIdOrName: string

  @description('Required. The principal ID of the principal (user/group/identity) to assign the role to.')
  principalId: string

  @description('Optional. The principal type of the assigned principal ID.')
  principalType: ('ServicePrincipal' | 'Group' | 'User' | 'ForeignGroup' | 'Device' | null)?

  @description('Optional. The description of the role assignment.')
  description: string?

  @description('Optional. The conditions on the role assignment. This limits the resources it can be assigned to. e.g.: @Resource[Microsoft.Storage/storageAccounts/blobServices/containers:ContainerName] StringEqualsIgnoreCase "foo_storage_container"')
  condition: string?

  @description('Optional. Version of the condition.')
  conditionVersion: '2.0'?

  @description('Optional. The Resource Id of the delegated managed identity resource.')
  delegatedManagedIdentityResourceId: string?
}[]?
