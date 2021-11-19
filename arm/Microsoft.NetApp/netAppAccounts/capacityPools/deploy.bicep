@description('Required. The name of the capacity pool.')
param netAppAccountName string

@description('Required. The name of the capacity pool.')
param name string

@description('Optional. Location of the pool volume.')
param location string = resourceGroup().location

@description('Optional. Tags for all resources.')
param tags object = {}

@description('Optional. The pool service level.')
@allowed([
  'Premium'
  'Standard'
  'StandardZRS'
  'Ultra'
])
param serviceLevel string = 'Standard'

@description('Required. Provisioned size of the pool (in bytes). Allowed values are in 4TiB chunks (value must be multiply of 4398046511104).')
param size int

@description('Optional. The qos type of the pool.')
@allowed([
  'Auto'
  'Manual'
])
param qosType string = 'Auto'

@description('Optional. List of volumnes to create in the capacity pool.')
param volumes array = []

@description('Optional. If enabled (true) the pool can contain cool Access enabled volumes.')
param coolAccess bool = false

@description('Optional. Array of role assignment objects that contain the \'roleDefinitionIdOrName\' and \'principalId\' to define RBAC role assignments on this resource. In the roleDefinitionIdOrName attribute, you can provide either the display name of the role definition, or it\'s fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'')
param roleAssignments array = []

@description('Optional. Customer Usage Attribution id (GUID). This GUID must be previously registered')
param cuaId string = ''

module pid_cuaId '.bicep/nested_cuaId.bicep' = if (!empty(cuaId)) {
  name: 'pid-${cuaId}'
  params: {}
}

resource capacityPool 'Microsoft.NetApp/netAppAccounts/capacityPools@2021-06-01' = {
  name: '${netAppAccountName}/${name}'
  location: location
  tags: tags
  properties: {
    serviceLevel: serviceLevel
    size: size
    qosType: qosType
    coolAccess: coolAccess
  }
}

module capacityPool_volumes './volumes/deploy.bicep' = [for (volume, index) in volumes: {
  name: '${deployment().name}-Vol-${index}'
  params: {
    netAppAccountName: netAppAccountName
    capacityPoolName: location
    name: name
    location: location
    serviceLevel: serviceLevel
    creationToken: volume.creationToken
    usageThreshold: volume.usageThreshold
    protocolTypes: contains(volume, 'protocolTypes') ? volume.protocolTypes : []
    subnetId: volume.subnetId
    exportPolicy: volume.exportPolicy
    roleAssignments: contains(volume, 'roleAssignments') ? volume.roleAssignments : []
  }
}]

module capacityPool_rbac '.bicep/nested_rbac.bicep' = [for (roleAssignment, index) in roleAssignments: {
  name: '${deployment().name}-Rbac-${index}'
  params: {
    roleAssignmentObj: roleAssignment
    resourceName: capacityPool.name
  }
}]

@description('The name of the Capacity Pool.')
output capacityPoolName string = capacityPool.name
@description('The Resource Id of the Capacity Pool.')
output capacityPoolResourceId string = capacityPool.id
@description('The name of the Resource Group the Capacity Pool was created in.')
output capacityPoolResourceGroup string = resourceGroup().name
