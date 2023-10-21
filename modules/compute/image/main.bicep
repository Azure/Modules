metadata name = 'Images'
metadata description = 'This module deploys a Compute Image.'
metadata owner = 'Azure/module-maintainers'

@description('Required. The name of the image.')
param name string

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Required. The Virtual Hard Disk.')
param osDiskBlobUri string

@description('Required. This property allows you to specify the type of the OS that is included in the disk if creating a VM from a custom image. - Windows or Linux.')
param osType string

@description('Optional. Specifies the caching requirements. Default: None for Standard storage. ReadOnly for Premium storage. - None, ReadOnly, ReadWrite.')
param osDiskCaching string

@description('Optional. Specifies the storage account type for the managed disk. NOTE: UltraSSD_LRS can only be used with data disks, it cannot be used with OS Disk. - Standard_LRS, Premium_LRS, StandardSSD_LRS, UltraSSD_LRS.')
param osAccountType string

@description('Optional. Default is false. Specifies whether an image is zone resilient or not. Zone resilient images can be created only in regions that provide Zone Redundant Storage (ZRS).')
param zoneResilient bool = false

@description('Optional. Gets the HyperVGenerationType of the VirtualMachine created from the image. - V1 or V2.')
param hyperVGeneration string = 'V1'

@description('Optional. Array of role assignment objects that contain the \'roleDefinitionIdOrName\' and \'principalId\' to define RBAC role assignments on this resource. In the roleDefinitionIdOrName attribute, you can provide either the display name of the role definition, or its fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.')
param roleAssignments roleAssignmentType

@description('Optional. Tags of the resource.')
param tags object = {}

@description('Optional. The extended location of the Image.')
param extendedLocation object = {}

@description('Optional. The source virtual machine from which Image is created.')
param sourceVirtualMachineResourceId string = ''

@description('Optional. Specifies the customer managed disk encryption set resource ID for the managed image disk.')
param diskEncryptionSetResourceId string = ''

@description('Optional. The managedDisk.')
param managedDiskResourceId string = ''

@description('Optional. Specifies the size of empty data disks in gigabytes. This element can be used to overwrite the name of the disk in a virtual machine image. This value cannot be larger than 1023 GB.')
param diskSizeGB int = 128

@description('Optional. The OS State. For managed images, use Generalized.')
@allowed([
  'Generalized'
  'Specialized'
])
param osState string = 'Generalized'

@description('Optional. The snapshot resource ID.')
param snapshotResourceId string = ''

@description('Optional. Specifies the parameters that are used to add a data disk to a virtual machine.')
param dataDisks array = []

@description('Optional. Enable telemetry via a Globally Unique Identifier (GUID).')
param enableDefaultTelemetry bool = true

var builtInRoleNames = {
  'Avere Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4f8fab4f-1852-4a58-a46a-8eaf358af14a')
  'Avere Operator': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'c025889f-8102-4ebf-b32c-fc0c6f0c6bd9')
  'Azure Center for SAP solutions administrator': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7b0c7e81-271f-4c71-90bf-e30bdfdbc2f7')
  'Azure Center for SAP solutions reader': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '05352d14-a920-4328-a0de-4cbe7430e26b')
  'Azure Center for SAP solutions service role': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'aabbc5dd-1af0-458b-a942-81af88f9c138')
  'Azure Kubernetes Service Policy Add-on Deployment': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '18ed5180-3e48-46fd-8541-4ea054d57064')
  'Compute Gallery Sharing Admin': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '1ef6a3be-d0ac-425d-8c01-acb62866290b')
  Contributor: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  'Data Operator for Managed Disks': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '959f8984-c045-4866-89c7-12bf9737be2e')
  'Desktop Virtualization Power On Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '489581de-a3bd-480d-9518-53dea7416b33')
  'Desktop Virtualization Power On Off Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '40c5ff49-9181-41f8-ae61-143b0e78555e')
  'Desktop Virtualization Virtual Machine Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a959dbd1-f747-45e3-8ba6-dd80f235f97c')
  'DevTest Labs User': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '76283e04-6283-4c54-8f91-bcf1374a3c64')
  'Disk Backup Reader': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '3e5e47e6-65f7-47ef-90b5-e5dd4d455f24')
  'Disk Pool Operator': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '60fc6e62-5479-42d4-8bf4-67625fcc2840')
  'Disk Restore Operator': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b50d9833-a0cb-478e-945f-707fcc997c13')
  'Disk Snapshot Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7efff54f-a5b4-42b5-a1c5-5411624893ce')
  'Log Analytics Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '92aaf0da-9dab-42b6-94a3-d43ce8d16293')
  'Log Analytics Reader': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '73c42c96-874c-492b-b04d-ab87d138a893')
  'Managed Application Contributor Role': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '641177b8-a67a-45b9-a033-47bc880bb21e')
  'Managed Application Operator Role': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'c7393b34-138c-406f-901b-d8cf2b17e6ae')
  'Managed Applications Reader': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b9331d33-8a36-4f8c-b097-4f54124fdb44')
  'Monitoring Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '749f88d5-cbae-40b8-bcfc-e573ddc772fa')
  'Monitoring Reader': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '43d0d8ad-25c7-4714-9337-8ba259a9fe05')
  Owner: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')
  Reader: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
  'Reservation Purchaser': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'f7b75c60-3036-4b75-91c3-6b41c27c1689')
  'Resource Policy Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '36243c78-bf99-498c-9df9-86d9f8d28608')
  'Role Based Access Control Administrator (Preview)': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'f58310d9-a9f6-439a-9e8d-f62e7b41a168')
  'User Access Administrator': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9')
  'Virtual Machine Administrator Login': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '1c0163c0-47e6-4577-8991-ea5c82e286e4')
  'Virtual Machine Contributor': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '9980e02c-c2be-4d73-94e8-173b1dc7cf3c')
  'Virtual Machine User Login': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'fb879df8-f326-4884-b1cf-06f3ad86be52')
  'VM Scanner Operator': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'd24ecba3-c1f4-40fa-a7bb-4588a071e8fd')
  'Windows Admin Center Administrator Login': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a6333a3e-0164-44c3-b281-7a577aff287f')
}

resource defaultTelemetry 'Microsoft.Resources/deployments@2022-09-01' = if (enableDefaultTelemetry) {
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

resource image 'Microsoft.Compute/images@2022-11-01' = {
  name: name
  location: location
  tags: tags
  extendedLocation: !empty(extendedLocation) ? extendedLocation : null
  properties: {
    storageProfile: {
      osDisk: {
        osType: osType
        blobUri: osDiskBlobUri
        caching: osDiskCaching
        storageAccountType: osAccountType
        osState: osState
        diskEncryptionSet: !empty(diskEncryptionSetResourceId) ? {
          id: diskEncryptionSetResourceId
        } : null
        diskSizeGB: diskSizeGB
        managedDisk: !empty(managedDiskResourceId) ? {
          id: managedDiskResourceId
        } : null
        snapshot: !empty(snapshotResourceId) ? {
          id: snapshotResourceId
        } : null
      }
      dataDisks: dataDisks
      zoneResilient: zoneResilient
    }
    hyperVGeneration: hyperVGeneration
    sourceVirtualMachine: !empty(sourceVirtualMachineResourceId) ? {
      id: sourceVirtualMachineResourceId
    } : null
  }
}

resource image_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for (roleAssignment, index) in (roleAssignments ?? []): {
  name: guid(image.id, roleAssignment.principalId, roleAssignment.roleDefinitionIdOrName)
  properties: {
    roleDefinitionId: contains(builtInRoleNames, roleAssignment.roleDefinitionIdOrName) ? builtInRoleNames[roleAssignment.roleDefinitionIdOrName] : roleAssignment.roleDefinitionIdOrName
    principalId: roleAssignment.principalId
    description: roleAssignment.?description
    principalType: roleAssignment.?principalType
    condition: roleAssignment.?condition
    conditionVersion: !empty(roleAssignment.?condition) ? (roleAssignment.?conditionVersion ?? '2.0') : null // Must only be set if condtion is set
    delegatedManagedIdentityResourceId: roleAssignment.?delegatedManagedIdentityResourceId
  }
  scope: image
}]

@description('The resource ID of the image.')
output resourceId string = image.id

@description('The resource group the image was deployed into.')
output resourceGroupName string = resourceGroup().name

@description('The name of the image.')
output name string = image.name

@description('The location the resource was deployed into.')
output location string = image.location
// =============== //
//   Definitions   //
// =============== //

type roleAssignmentType = {
  @description('Required. The name of the role to assign. If it cannot be found you can specify the role definition ID instead.')
  roleDefinitionIdOrName: string

  @description('Required. The principal ID of the principal (user/group/identity) to assign the role to.')
  principalId: string

  @description('Optional. The principal type of the assigned principal ID.')
  principalType: ('ServicePrincipal' | 'Group' | 'User' | 'ForeignGroup' | 'Device' | null)?

  @description('Optional. The description of the role assignment.')
  description: string?

  @description('Optional. The conditions on the role assignment. This limits the resources it can be assigned to. e.g.: @Resource[Microsoft.Storage/storageAccounts/blobServices/containers:ContainerName] StringEqualsIgnoreCase "foo_storage_container"')
  condition: string?

  @description('Optional. Version of the condition.')
  conditionVersion: '2.0'?

  @description('Optional. The Resource Id of the delegated managed identity resource.')
  delegatedManagedIdentityResourceId: string?
}[]?
