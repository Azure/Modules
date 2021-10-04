targetScope = 'managementGroup'
param policySetDefinitionName string
param policySetDefinitionProperties object
param managementGroupId string

resource policySetDefinition 'Microsoft.Authorization/policySetDefinitions@2020-09-01' = {
  name: policySetDefinitionName
  properties: policySetDefinitionProperties
}

output policySetDefinitionId string = extensionResourceId(tenantResourceId('Microsoft.Management/managementGroups',managementGroupId),'Microsoft.Authorization/policySetDefinitions',policySetDefinition.name)
