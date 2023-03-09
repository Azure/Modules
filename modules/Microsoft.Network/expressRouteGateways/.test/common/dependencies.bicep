@description('Required. The name of the virtual WAN to create.')
param virtualWANName string

@description('Required. The name of the virtual Hub to create.')
param virtualHubName string

@description('Required. The address prefix of the virtual Hub to create.')
param addressPrefix string

@description('Optional. The location to deploy resources to.')
param location string = resourceGroup().location

resource virtualWan 'Microsoft.Network/virtualWans@2021-05-01' = {
    name: virtualWANName
    location: location
}

resource virtualHub 'Microsoft.Network/virtualHubs@2022-07-01' = {
    name: virtualHubName
    location: location
    properties: {
        addressPrefix: addressPrefix
        virtualWan: {
            id: virtualWan.id
        }
    }
}

@description('The resource ID of the created Virtual Hub.')
output virtualHubResourceId string = virtualHub.id
