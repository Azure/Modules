targetScope = 'subscription'
param policyAssignmentName string
param properties object
param subscriptionId string
param identity object
param location string = deployment().location

resource policyAssignment 'Microsoft.Authorization/policyAssignments@2020-09-01' = {
  name: policyAssignmentName
  location: location
  properties: properties
  identity: identity
}

output policyAssignmentId string =   subscriptionResourceId(subscriptionId,'Microsoft.Authorization/policySetDefinitions',policyAssignment.name)
output policyAssignmentPrincipalId string = (identity.type == 'SystemAssigned') ? policyAssignment.identity.principalId : ''
