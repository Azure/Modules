targetScope = 'subscription'

metadata name = 'Using large parameter set'
metadata description = 'This instance deploys the module with most of its features enabled.'

// ========== //
// Parameters //
// ========== //

@description('Optional. The name of the resource group to deploy for testing purposes.')
@maxLength(90)
param resourceGroupName string = 'dep-${namePrefix}-datafactory.factories-${serviceShort}-rg'

@description('Optional. The location to deploy resources to.')
param location string = deployment().location

@description('Optional. A short identifier for the kind of deployment. Should be kept short to not run into resource-name length-constraints.')
param serviceShort string = 'dffcom'

@description('Optional. Enable telemetry via a Globally Unique Identifier (GUID).')
param enableDefaultTelemetry bool = true

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
    virtualNetworkName: 'dep-${namePrefix}-vnet-${serviceShort}'
    keyVaultName: 'dep-${namePrefix}-kv-${serviceShort}'
    managedIdentityName: 'dep-${namePrefix}-msi-${serviceShort}'
    storageAccountName: 'dep${namePrefix}st${serviceShort}'
  }
}

// Diagnostics
// ===========
module diagnosticDependencies '../../../../.shared/.templates/diagnostic.dependencies.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-diagnosticDependencies'
  params: {
    storageAccountName: 'dep${namePrefix}diasa${serviceShort}01'
    logAnalyticsWorkspaceName: 'dep-${namePrefix}-law-${serviceShort}'
    eventHubNamespaceEventHubName: 'dep-${namePrefix}-evh-${serviceShort}'
    eventHubNamespaceName: 'dep-${namePrefix}-evhns-${serviceShort}'
    location: location
  }
}

// ============== //
// Test Execution //
// ============== //

module testDeployment '../../main.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-test-${serviceShort}'
  params: {
    enableDefaultTelemetry: enableDefaultTelemetry
    name: '${namePrefix}${serviceShort}001'
    cMKKeyName: nestedDependencies.outputs.keyVaultEncryptionKeyName
    cMKKeyVaultResourceId: nestedDependencies.outputs.keyVaultResourceId
    cMKUserAssignedIdentityResourceId: nestedDependencies.outputs.managedIdentityResourceId
    diagnosticSettings: [
      {
        name: 'customSetting'
        metricCategories: [
          {
            category: 'AllMetrics'
          }
        ]
        eventHubName: diagnosticDependencies.outputs.eventHubNamespaceEventHubName
        eventHubAuthorizationRuleResourceId: diagnosticDependencies.outputs.eventHubAuthorizationRuleId
        storageAccountResourceId: diagnosticDependencies.outputs.storageAccountResourceId
        workspaceResourceId: diagnosticDependencies.outputs.logAnalyticsWorkspaceResourceId
      }
    ]
    gitConfigureLater: true
    globalParameters: {
      testParameter1: {
        type: 'String'
        value: 'testValue1'
      }
    }
    integrationRuntimes: [
      {
        managedVirtualNetworkName: 'default'
        name: 'AutoResolveIntegrationRuntime'
        type: 'Managed'
        typeProperties: {
          computeProperties: {
            location: 'AutoResolve'
          }
        }
      }

      {
        name: 'TestRuntime'
        type: 'SelfHosted'
      }
    ]
    lock: {
      kind: 'CanNotDelete'
      name: 'myCustomLockName'
    }
    managedPrivateEndpoints: [
      {
        fqdns: [
          nestedDependencies.outputs.storageAccountBlobEndpoint
        ]
        groupId: 'blob'
        name: '${nestedDependencies.outputs.storageAccountName}-managed-privateEndpoint'
        privateLinkResourceId: nestedDependencies.outputs.storageAccountResourceId
      }
    ]
    managedVirtualNetworkName: 'default'
    privateEndpoints: [
      {
        privateDnsZoneResourceIds: [
          nestedDependencies.outputs.privateDNSZoneResourceId
        ]
        subnetResourceId: nestedDependencies.outputs.subnetResourceId
        tags: {
          'hidden-title': 'This is visible in the resource name'
          application: 'CARML'
        }
      }
    ]
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Reader'
        principalId: nestedDependencies.outputs.managedIdentityPrincipalId
        principalType: 'ServicePrincipal'
      }
    ]
    systemAssignedIdentity: true
    userAssignedIdentities: {
      '${nestedDependencies.outputs.managedIdentityResourceId}': {}
    }
    tags: {
      'hidden-title': 'This is visible in the resource name'
      Environment: 'Non-Prod'
      Role: 'DeploymentValidation'
    }
  }
}
