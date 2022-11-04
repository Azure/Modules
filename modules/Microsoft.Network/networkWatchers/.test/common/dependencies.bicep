@description('Optional. The location to deploy to.')
param location string = resourceGroup().location

@description('Required. The name of the Virtual Network to create.')
param virtualNetworkName string

@description('Required. The name of the Managed Identity to create.')
param managedIdentityName string

@description('Required. The name of the first Network Security Group to create.')
param firstNetworkSecurityGroupName string

@description('Required. The name of the second Network Security Group to create.')
param secondNetworkSecurityGroupName string

@description('Required. The name of the Virtual Machine to create.')
param virtualMachineName string

@description('Optional. The password to leverage for the VM login.')
@secure()
param password string = newGuid()

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-01-01' = {
    name: virtualNetworkName
    location: location
    properties: {
        addressSpace: {
            addressPrefixes: [
                '10.0.0.0/24'
            ]
        }
        subnets: [
            {
                name: 'defaultSubnet'
                properties: {
                    addressPrefix: '10.0.0.0/24'
                }
            }
        ]
    }
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
    name: managedIdentityName
    location: location
}

resource firstNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
    name: firstNetworkSecurityGroupName
    location: location
}

resource secondNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
    name: secondNetworkSecurityGroupName
    location: location
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2022-05-01' = {
    name: '${virtualMachineName}-nic'
    location: location
    properties: {
        ipConfigurations: [
            {
                name: 'ipconfig01'
                properties: {
                    subnet: {
                        id: virtualNetwork.properties.subnets[0].id
                    }
                }
            }
        ]
    }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2022-08-01' = {
    name: virtualMachineName
    location: location
    properties: {
        networkProfile: {
            networkInterfaces: [
                {
                    id: networkInterface.id
                    properties: {
                        deleteOption: 'Delete'
                        primary: true
                    }
                }
            ]
        }
        storageProfile: {
            imageReference: {
                offer: 'UbuntuServer'
                publisher: 'Canonical'
                sku: '18.04-LTS'
                version: 'latest'
            }
        }
        hardwareProfile: {
            vmSize: 'Standard_B1ms'
        }
        osProfile: {
            adminUsername: '${virtualMachineName}cake'
            adminPassword: password
            computerName: virtualMachineName
            linuxConfiguration: {
                disablePasswordAuthentication: false
            }
        }
    }
}

resource extension 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = {
    name: 'NetworkWatcherAgent'
    parent: virtualMachine
    location: location
    properties: {
        publisher: 'Microsoft.Azure.NetworkWatcher'
        type: 'NetworkWatcherAgentLinux'
        typeHandlerVersion: '1.4'
        autoUpgradeMinorVersion: true
        enableAutomaticUpgrade: false
        settings: {}
        protectedSettings: {}
        suppressFailures: false
    }
}

@description('The principal ID of the created Managed Identity.')
output managedIdentityPrincipalId string = managedIdentity.properties.principalId

@description('The resource ID of the created Virtual Machine.')
output virtualMachineResourceId string = virtualMachine.id

@description('The resource ID of the first created Network Security Group.')
output firstNetworkSecurityGroupResourceId string = firstNetworkSecurityGroup.id

@description('The resource ID of the second created Network Security Group.')
output secondNetworkSecurityGroupResourceId string = secondNetworkSecurityGroup.id
