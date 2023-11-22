targetScope = 'subscription'

metadata name = 'WAF-aligned'
<<<<<<< HEAD
metadata description = 'This instance deploys the module in alignment with the best-pratices of the Well-Architectured-Framework.'
=======
metadata description = 'This instance deploys the module in alignment with the best-practices of the Azure Well-Architected Framework.'
>>>>>>> 3d827c3621e7d83ad5b9d9266e593f0afc6b7683

// ========== //
// Parameters //
// ========== //

@description('Optional. The name of the resource group to deploy for testing purposes.')
@maxLength(90)
param resourceGroupName string = 'dep-${namePrefix}-managedidentity.userassignedidentities-${serviceShort}-rg'

@description('Optional. The location to deploy resources to.')
param location string = deployment().location

@description('Optional. A short identifier for the kind of deployment. Should be kept short to not run into resource-name length-constraints.')
param serviceShort string = 'miuaiwaf'

<<<<<<< HEAD
=======
@description('Optional. Enable telemetry via a Globally Unique Identifier (GUID).')
param enableDefaultTelemetry bool = true

>>>>>>> 3d827c3621e7d83ad5b9d9266e593f0afc6b7683
@description('Optional. A token to inject into the name of each resource.')
param namePrefix string = '[[namePrefix]]'

// ============ //
// Dependencies //
// ============ //

// General resources
// =================
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

module nestedDependencies 'dependencies.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-nestedDependencies'
  params: {
    managedIdentityName: 'dep-${namePrefix}-msi-${serviceShort}'
  }
}

// ============== //
// Test Execution //
// ============== //
<<<<<<< HEAD
@batchSize(1)
module testDeployment '../../../main.bicep' =[for iteration in [ 'init', 'idem' ]: {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-test-${serviceShort}-${iteration}'
  params: {
=======

@batchSize(1)
module testDeployment '../../../main.bicep' = [for iteration in [ 'init', 'idem' ]: {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-test-${serviceShort}-${iteration}'
  params: {
    enableDefaultTelemetry: enableDefaultTelemetry
>>>>>>> 3d827c3621e7d83ad5b9d9266e593f0afc6b7683
    name: '${namePrefix}${serviceShort}001'
    lock: {
      kind: 'CanNotDelete'
      name: 'myCustomLockName'
    }
    federatedIdentityCredentials: [
      {
        name: 'test-fed-cred-${serviceShort}-001'
        audiences: [
          'api://AzureADTokenExchange'
        ]
        issuer: 'https://contoso.com/${subscription().tenantId}/${guid(deployment().name)}/'
        subject: 'system:serviceaccount:default:workload-identity-sa'
      }
    ]
<<<<<<< HEAD
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Reader'
        principalId: nestedDependencies.outputs.managedIdentityPrincipalId
        principalType: 'ServicePrincipal'
      }
    ]
=======
>>>>>>> 3d827c3621e7d83ad5b9d9266e593f0afc6b7683
    tags: {
      'hidden-title': 'This is visible in the resource name'
      Environment: 'Non-Prod'
      Role: 'DeploymentValidation'
    }
  }
<<<<<<< HEAD
}
]
=======
}]
>>>>>>> 3d827c3621e7d83ad5b9d9266e593f0afc6b7683
