metadata name = 'User Assigned Identity Federated Identity Credential'
metadata description = 'This module deploys a User Assigned Identity Federated Identity Credential.'
metadata owner = 'Azure/module-maintainers'

@description('Conditional. The name of the parent user assigned identity. Required if the template is used in a standalone deployment.')
param userAssignedIdentityName string

@description('Required. The name of the secret.')
param name string

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Required. The list of audiences that can appear in the issued token. Should be set to api://AzureADTokenExchange for Azure AD. It says what Microsoft identity platform should accept in the aud claim in the incoming token. This value represents Azure AD in your external identity provider and has no fixed value across identity providers - you might need to create a new application registration in your IdP to serve as the audience of this token.')
param audiences array

@description('Required. The URL of the issuer to be trusted. Must match the issuer claim of the external token being exchanged.')
param issuer string

@description('Required. The identifier of the external software workload within the external identity provider. Like the audience value, it has no fixed format, as each IdP uses their own - sometimes a GUID, sometimes a colon delimited identifier, sometimes arbitrary strings. The value here must match the sub claim within the token presented to Azure AD.')
param subject string

@description('Optional. Enable/Disable usage telemetry for module.')
param enableTelemetry bool = true

resource avmTelemetry 'Microsoft.Resources/deployments@2023-07-01' = if (enableTelemetry) {
  name: '46d3xbcp.res.managedidentity-userassignedidentity.${replace('-..--..-', '.', '-')}.${substring(uniqueString(deployment().name, location), 0, 4)}'
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
      outputs: {
        telemetry: {
          type: 'String'
          value: 'For more information, see https://aka.ms/avm/TelemetryInfo'
        }
      }
    }
  }
}

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: userAssignedIdentityName
}

resource federatedIdentityCredential 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31' = {
  name: name
  parent: userAssignedIdentity
  properties: {
    audiences: audiences
    issuer: issuer
    subject: subject
  }
}

@description('The name of the federated identity credential.')
output name string = federatedIdentityCredential.name

@description('The resource ID of the federated identity credential.')
output resourceId string = federatedIdentityCredential.id

@description('The name of the resource group the federated identity credential was created in.')
output resourceGroupName string = resourceGroup().name
