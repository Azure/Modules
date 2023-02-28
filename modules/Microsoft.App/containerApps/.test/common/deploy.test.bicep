targetScope = 'subscription'

// ========== //
// Parameters //
// ========== //

@description('Optional. The name of the resource group to deploy for testing purposes.')
@maxLength(90)
param resourceGroupName string = 'ms.app.containerApps-${serviceShort}-rg'

@description('Optional. The location to deploy resources to.')
param location string = deployment().location

@description('Optional. A short identifier for the kind of deployment. Should be kept short to not run into resource-name length-constraints.')
param serviceShort string = 'mcappcom'

@description('Optional. Enable telemetry via a Globally Unique Identifier (GUID).')
param enableDefaultTelemetry bool = true

// =========== //
// Deployments //
// =========== //

// General resources
// =================
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

module nestedDependencies 'dependencies.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-paramNested'
  params: {
    location: location
    logAnalyticsWorkspaceName: 'dep-<<namePrefix>>-law-${serviceShort}'
    managedEnvironmentName: 'dep-<<namePrefix>>-menv-${serviceShort}'
    managedIdentityName: 'dep-<<namePrefix>>-msi-${serviceShort}'
  }
}

// ============== //
// Test Execution //
// ============== //

module testDeployment '../../deploy.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-test-${serviceShort}'
  params: {
    containerImage: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
    name: '<<namePrefix>>${serviceShort}001'
    tags: {
      Env: 'test'
    }
    enableDefaultTelemetry: enableDefaultTelemetry
    environmentId: nestedDependencies.outputs.managedEnvironmentResourceId
    containerName: 'simple-hello-world-container'
    containerResources: {
      cpu: '0.25'
      memory: '0.5Gi'
    }
    location: location
    lock: 'CanNotDelete'
    userAssignedIdentities: {
      '${nestedDependencies.outputs.managedIdentityResourceId}': {}
    }
  }
}
