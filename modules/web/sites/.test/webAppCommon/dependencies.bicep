@description('Optional. The location to deploy resources to.')
param location string = resourceGroup().location

@description('Required. The name of the Virtual Network to create.')
param virtualNetworkName string

@description('Required. The name of the Managed Identity to create.')
param managedIdentityName string

@description('Required. The name of the Server Farm to create.')
param serverFarmName string

@description('Required. The name of the Relay Namespace to create.')
param namespaceName string

@description('Required. The name of the Hybrid Connection to create.')
param hybridConnectionName string

var addressPrefix = '10.0.0.0/16'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-01-01' = {
    name: virtualNetworkName
    location: location
    properties: {
        addressSpace: {
            addressPrefixes: [
                addressPrefix
            ]
        }
        subnets: [
            {
                name: 'defaultSubnet'
                properties: {
                    addressPrefix: addressPrefix
                }
            }
        ]
    }
}

resource privateDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
    name: 'privatelink.azurewebsites.net'
    location: 'global'

    resource virtualNetworkLinks 'virtualNetworkLinks@2020-06-01' = {
        name: '${virtualNetwork.name}-vnetlink'
        location: 'global'
        properties: {
            virtualNetwork: {
                id: virtualNetwork.id
            }
            registrationEnabled: false
        }
    }
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
    name: managedIdentityName
    location: location
}

resource serverFarm 'Microsoft.Web/serverfarms@2022-03-01' = {
    name: serverFarmName
    location: location
    sku: {
        name: 'S1'
        tier: 'Standard'
        size: 'S1'
        family: 'S'
        capacity: 1
    }
    properties: {}
}

resource namespace 'Microsoft.Relay/namespaces@2021-11-01' = {
    name: namespaceName
    location: location
    sku: {
        name: 'Standard'
    }
    properties: {}
}

resource hybridConnection 'Microsoft.Relay/namespaces/hybridConnections@2021-11-01' = {
    name: hybridConnectionName
    parent: namespace
    properties: {
        requiresClientAuthorization: true
        userMetadata: '[{"key":"endpoint","value":"db-server.constoso.com:1433"}]'
    }
}

resource authorizationRule 'Microsoft.Relay/namespaces/hybridConnections/authorizationRules@2021-11-01' = {
    name: 'defaultSender'
    parent: hybridConnection
    properties: {
        rights: [
            'Send'
        ]
    }
}

@description('The resource ID of the created Virtual Network Subnet.')
output subnetResourceId string = virtualNetwork.properties.subnets[0].id

@description('The principal ID of the created Managed Identity.')
output managedIdentityPrincipalId string = managedIdentity.properties.principalId

@description('The resource ID of the created Managed Identity.')
output managedIdentityResourceId string = managedIdentity.id

@description('The resource ID of the created Server Farm.')
output serverFarmResourceId string = serverFarm.id

@description('The resource ID of the created Private DNS Zone.')
output privateDNSZoneResourceId string = privateDNSZone.id

@description('The resource ID of the created Hybrid Connection.')
output hybridConnectionResourceId string = hybridConnection.id
