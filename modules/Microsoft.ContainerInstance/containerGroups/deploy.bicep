@description('Required. Name for the container group.')
param name string

@description('Required. The containers and their respective config within the container group.')
param containers array

@description('Conditional. Ports to open on the public IP address. Must include all ports assigned on container level. Required if `ipAddressType` is set to `public`.')
param ipAddressPorts array = []

@description('Optional. The operating system type required by the containers in the container group. - Windows or Linux.')
param osType string = 'Linux'

@allowed([
  'Always'
  'OnFailure'
  'Never'
])
@description('Optional. Restart policy for all containers within the container group. - Always: Always restart. OnFailure: Restart on failure. Never: Never restart. - Always, OnFailure, Never.')
param restartPolicy string = 'Always'

@allowed([
  'Public'
  'Private'
])
@description('Optional. Specifies if the IP is exposed to the public internet or private VNET. - Public or Private.')
param ipAddressType string = 'Public'

@description('Optional. The image registry credentials by which the container group is created from.')
param imageRegistryCredentials array = []

@description('Optional. Location for all Resources.')
param location string = resourceGroup().location

@allowed([
  'Noreuse'
  'ResourceGroupReuse'
  'SubscriptionReuse'
  'TenantReuse'
  'Unsecure'
])
@description('Optional. Specify level of protection of the domain name label.')
param autoGeneratedDomainNameLabelScope string = 'TenantReuse'

@description('Optional. The Dns name label for the resource.')
param dnsNameLabel string = ''

@description('Optional. List of dns servers used by the containers for lookups.')
param dnsNameServers array = []

@description('Optional. DNS search domain which will be appended to each DNS lookup.')
param dnsSearchDomains string = ''

@description('Optional. A list of container definitions which will be executed before the application container starts.')
param initContainers array = []

@description('Optional. Resource ID of the subnet. Only specify when ipAddressType is Private.')
param subnetId string = ''

@description('Optional. Specify if volumes (emptyDir, AzureFileShare or GitRepo) shall be attached to your containergroup.')
param volumes array = []

@allowed([
  ''
  'CanNotDelete'
  'ReadOnly'
])
@description('Optional. Specify the type of lock.')
param lock string = ''

@description('Optional. Enables system assigned managed identity on the resource.')
param systemAssignedIdentity bool = false

@description('Optional. The ID(s) to assign to the resource.')
param userAssignedIdentities object = {}

@description('Optional. Tags of the resource.')
param tags object = {}

@description('Optional. Enable telemetry via a Globally Unique Identifier (GUID).')
param enableDefaultTelemetry bool = true

@description('Optional. The container group SKU.')
@allowed([
  'Dedicated'
  'Standard'
])
param sku string = 'Standard'

@description('Optional. The resource ID of a key vault to reference a customer managed key for encryption from.')
param cMKKeyVaultResourceId string = ''

@description('Optional. The name of the customer managed key to use for encryption.')
param cMKKeyName string = ''

@description('Optional. The version of the customer managed key to reference for encryption. If not provided, the latest key version is used.')
param cMKKeyVersion string = ''

var identityType = systemAssignedIdentity ? (!empty(userAssignedIdentities) ? 'SystemAssigned,UserAssigned' : 'SystemAssigned') : (!empty(userAssignedIdentities) ? 'UserAssigned' : 'None')

var identity = identityType != 'None' ? {
  type: identityType
  userAssignedIdentities: !empty(userAssignedIdentities) ? userAssignedIdentities : null
} : null

resource defaultTelemetry 'Microsoft.Resources/deployments@2021-04-01' = if (enableDefaultTelemetry) {
  name: 'pid-47ed15a6-730a-4827-bcb4-0fd963ffbd82-${uniqueString(deployment().name, location)}'
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}

resource cmkKeyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = if (!empty(cMKKeyVaultResourceId)) {
  name: last(split(cMKKeyVaultResourceId, '/'))
  scope: resourceGroup(split(cMKKeyVaultResourceId, '/')[2], split(cMKKeyVaultResourceId, '/')[4])
}

resource cMKKeyVaultKey 'Microsoft.KeyVault/vaults/keys@2021-10-01' existing = if (!empty(cMKKeyVaultResourceId) && !empty(cMKKeyName)) {
  name: '${last(split(cMKKeyVaultResourceId, '/'))}/${cMKKeyName}'
  scope: resourceGroup(split(cMKKeyVaultResourceId, '/')[2], split(cMKKeyVaultResourceId, '/')[4])
}

resource containergroup 'Microsoft.ContainerInstance/containerGroups@2021-10-01' = {
  name: name
  location: location
  identity: identity
  tags: tags
  properties: union({
      containers: containers
      encryptionProperties: !empty(cMKKeyName) ? {
        keyName: cMKKeyName
        keyVersion: !empty(cMKKeyVersion) ? cMKKeyVersion : last(split(cMKKeyVaultKey.properties.keyUriWithVersion, '/'))
        vaultBaseUrl: cmkKeyVault.properties.vaultUri
      } : null
      imageRegistryCredentials: imageRegistryCredentials
      initContainers: initContainers
      restartPolicy: restartPolicy
      osType: osType
      ipAddress: {
        type: ipAddressType
        autoGeneratedDomainNameLabelScope: !empty(dnsNameServers) ? autoGeneratedDomainNameLabelScope : null
        dnsNameLabel: dnsNameLabel
        ports: ipAddressPorts
      }
      sku: sku
      subnetIds: !empty(subnetId) ? [
        {
          id: subnetId
        }
      ] : null
      volumes: volumes
    }, !empty(dnsNameServers) ? {
      dnsConfig: {
        nameServers: dnsNameServers
        searchDomains: dnsSearchDomains
      }
    } : {})
}

resource containergroup_lock 'Microsoft.Authorization/locks@2020-05-01' = if (!empty(lock)) {
  name: '${containergroup.name}-${lock}-lock'
  properties: {
    level: any(lock)
    notes: lock == 'CanNotDelete' ? 'Cannot delete resource or child resources.' : 'Cannot modify the resource or child resources.'
  }
  scope: containergroup
}

@description('The name of the container group.')
output name string = containergroup.name

@description('The resource ID of the container group.')
output resourceId string = containergroup.id

@description('The resource group the container group was deployed into.')
output resourceGroupName string = resourceGroup().name

@description('The IPv4 address of the container group.')
output iPv4Address string = containergroup.properties.ipAddress.ip

@description('The principal ID of the system assigned identity.')
output systemAssignedPrincipalId string = systemAssignedIdentity && contains(containergroup.identity, 'principalId') ? containergroup.identity.principalId : ''

@description('The location the resource was deployed into.')
output location string = containergroup.location
