// Main resource
@description('Optional. The name of the virtual machine to be created. You should use a unique prefix to reduce name collisions in Active Directory. If no value is provided, a 10 character long unique string will be generated based on the Resource Group\'s name.')
param name string = take(toLower(uniqueString(resourceGroup().name)), 10)

@description('Optional. Specifies whether the computer names should be transformed. The transformation is performed on all computer names. Available transformations are \'none\' (Default), \'uppercase\' and \'lowercase\'.')
@allowed([
  'none'
  'uppercase'
  'lowercase'
])
param vmComputerNamesTransformation string = 'none'

@description('Required. Specifies the size for the VMs.')
param vmSize string

@description('Optional. This property can be used by user in the request to enable or disable the Host Encryption for the virtual machine. This will enable the encryption for all the disks including Resource/Temp disk at host itself. For security reasons, it is recommended to set encryptionAtHost to True. Restrictions: Cannot be enabled if Azure Disk Encryption (guest-VM encryption using bitlocker/DM-Crypt) is enabled on your VMs.')
param encryptionAtHost bool = true

@description('Optional. Specifies the SecurityType of the virtual machine. It is set as TrustedLaunch to enable UefiSettings.')
param securityType string = ''

@description('Optional. Specifies whether secure boot should be enabled on the virtual machine. This parameter is part of the UefiSettings. SecurityType should be set to TrustedLaunch to enable UefiSettings.')
param secureBootEnabled bool = false

@description('Optional. Specifies whether vTPM should be enabled on the virtual machine. This parameter is part of the UefiSettings.  SecurityType should be set to TrustedLaunch to enable UefiSettings.')
param vTpmEnabled bool = false

@description('Required. OS image reference. In case of marketplace images, it\'s the combination of the publisher, offer, sku, version attributes. In case of custom images it\'s the resource ID of the custom image.')
param imageReference object

@description('Optional. Specifies information about the marketplace image used to create the virtual machine. This element is only used for marketplace images. Before you can use a marketplace image from an API, you must enable the image for programmatic use.')
param plan object = {}

@description('Required. Specifies the OS disk. For security reasons, it is recommended to specify DiskEncryptionSet into the osDisk object.  Restrictions: DiskEncryptionSet cannot be enabled if Azure Disk Encryption (guest-VM encryption using bitlocker/DM-Crypt) is enabled on your VMs.')
param osDisk object

@description('Optional. Specifies the data disks. For security reasons, it is recommended to specify DiskEncryptionSet into the dataDisk object. Restrictions: DiskEncryptionSet cannot be enabled if Azure Disk Encryption (guest-VM encryption using bitlocker/DM-Crypt) is enabled on your VMs.')
param dataDisks array = []

@description('Optional. The flag that enables or disables a capability to have one or more managed data disks with UltraSSD_LRS storage account type on the VM or VMSS. Managed disks with storage account type UltraSSD_LRS can be added to a virtual machine or virtual machine scale set only if this property is enabled.')
param ultraSSDEnabled bool = false

@description('Required. Administrator username.')
@secure()
param adminUsername string

@description('Optional. When specifying a Windows Virtual Machine, this value should be passed.')
@secure()
param adminPassword string = ''

@description('Optional. Custom data associated to the VM, this value will be automatically converted into base64 to account for the expected VM format.')
param customData string = ''

@description('Optional. Specifies set of certificates that should be installed onto the virtual machine.')
param certificatesToBeInstalled array = []

@description('Optional. Specifies the priority for the virtual machine.')
@allowed([
  'Regular'
  'Low'
  'Spot'
])
param vmPriority string = 'Regular'

@description('Optional. Specifies the eviction policy for the low priority virtual machine. Will result in \'Deallocate\' eviction policy.')
param enableEvictionPolicy bool = false

@description('Optional. Specifies the maximum price you are willing to pay for a low priority VM/VMSS. This price is in US Dollars.')
param maxPriceForLowPriorityVm string = ''

@description('Optional. Specifies resource ID about the dedicated host that the virtual machine resides in.')
param dedicatedHostId string = ''

@description('Optional. Specifies that the image or disk that is being used was licensed on-premises. This element is only used for images that contain the Windows Server operating system.')
@allowed([
  'Windows_Client'
  'Windows_Server'
  ''
])
param licenseType string = ''

@description('Optional. The list of SSH public keys used to authenticate with linux based VMs.')
param publicKeys array = []

@description('Optional. Enables system assigned managed identity on the resource. The system-assigned managed identity will automatically be enabled if extensionAadJoinConfig.enabled = "True".')
param systemAssignedIdentity bool = false

@description('Optional. The ID(s) to assign to the resource.')
param userAssignedIdentities object = {}

@description('Optional. Whether boot diagnostics should be enabled on the Virtual Machine. Boot diagnostics will be enabled with a managed storage account if no bootDiagnosticsStorageAccountName value is provided. If bootDiagnostics and bootDiagnosticsStorageAccountName values are not provided, boot diagnostics will be disabled.')
param bootDiagnostics bool = false

@description('Optional. Custom storage account used to store boot diagnostic information. Boot diagnostics will be enabled with a custom storage account if a value is provided.')
param bootDiagnosticStorageAccountName string = ''

@description('Optional. Storage account boot diagnostic base URI.')
param bootDiagnosticStorageAccountUri string = '.blob.${environment().suffixes.storage}/'

@description('Optional. Resource ID of a proximity placement group.')
param proximityPlacementGroupResourceId string = ''

@description('Optional. Resource ID of an availability set. Cannot be used in combination with availability zone nor scale set.')
param availabilitySetResourceId string = ''

@description('Optional. If set to 1, 2 or 3, the availability zone for all VMs is hardcoded to that value. If zero, then availability zones is not used. Cannot be used in combination with availability set nor scale set.')
@allowed([
  0
  1
  2
  3
])
param availabilityZone int = 0

// External resources
@description('Required. Configures NICs and PIPs.')
param nicConfigurations array

@description('Optional. The name of the PIP diagnostic setting, if deployed.')
param pipDiagnosticSettingsName string = '${name}-diagnosticSettings'

@description('Optional. The name of logs that will be streamed. "allLogs" includes all possible logs for the resource.')
@allowed([
  'allLogs'
  'DDoSProtectionNotifications'
  'DDoSMitigationFlowLogs'
  'DDoSMitigationReports'
])
param pipdiagnosticLogCategoriesToEnable array = [
  'allLogs'
]

@description('Optional. The name of metrics that will be streamed.')
@allowed([
  'AllMetrics'
])
param pipdiagnosticMetricsToEnable array = [
  'AllMetrics'
]

@description('Optional. The name of the NIC diagnostic setting, if deployed.')
param nicDiagnosticSettingsName string = '${name}-diagnosticSettings'

@description('Optional. The name of metrics that will be streamed.')
@allowed([
  'AllMetrics'
])
param nicdiagnosticMetricsToEnable array = [
  'AllMetrics'
]

@description('Optional. Recovery service vault name to add VMs to backup.')
param backupVaultName string = ''

@description('Optional. Resource group of the backup recovery service vault. If not provided the current resource group name is considered by default.')
param backupVaultResourceGroup string = resourceGroup().name

@description('Optional. Backup policy the VMs should be using for backup. If not provided, it will use the DefaultPolicy from the backup recovery service vault.')
param backupPolicyName string = 'DefaultPolicy'

// Child resources
@description('Optional. Specifies whether extension operations should be allowed on the virtual machine. This may only be set to False when no extensions are present on the virtual machine.')
param allowExtensionOperations bool = true

@description('Optional. Required if name is specified. Password of the user specified in user parameter.')
@secure()
param extensionDomainJoinPassword string = ''

@description('Optional. The configuration for the [Domain Join] extension. Must at least contain the ["enabled": true] property to be executed.')
param extensionDomainJoinConfig object = {
  enabled: false
}

@description('Optional. The configuration for the [AAD Join] extension. Must at least contain the ["enabled": true] property to be executed.')
param extensionAadJoinConfig object = {
  enabled: false
}

@description('Optional. The configuration for the [Anti Malware] extension. Must at least contain the ["enabled": true] property to be executed.')
param extensionAntiMalwareConfig object = {
  enabled: false
}

@description('Optional. The configuration for the [Monitoring Agent] extension. Must at least contain the ["enabled": true] property to be executed.')
param extensionMonitoringAgentConfig object = {
  enabled: false
}

@description('Optional. Resource ID of the monitoring log analytics workspace. Must be set when extensionMonitoringAgentConfig is set to true.')
param monitoringWorkspaceId string = ''

@description('Optional. The configuration for the [Dependency Agent] extension. Must at least contain the ["enabled": true] property to be executed.')
param extensionDependencyAgentConfig object = {
  enabled: false
}

@description('Optional. The configuration for the [Network Watcher Agent] extension. Must at least contain the ["enabled": true] property to be executed.')
param extensionNetworkWatcherAgentConfig object = {
  enabled: false
}

@description('Optional. The configuration for the [Azure Disk Encryption] extension. Must at least contain the ["enabled": true] property to be executed. Restrictions: Cannot be enabled on disks that have encryption at host enabled. Managed disks encrypted using Azure Disk Encryption cannot be encrypted using customer-managed keys.')
param extensionAzureDiskEncryptionConfig object = {
  enabled: false
}

@description('Optional. The configuration for the [Desired State Configuration] extension. Must at least contain the ["enabled": true] property to be executed.')
param extensionDSCConfig object = {
  enabled: false
}

@description('Optional. The configuration for the [Custom Script] extension. Must at least contain the ["enabled": true] property to be executed.')
param extensionCustomScriptConfig object = {
  enabled: false
  fileData: []
}

@description('Optional. Any object that contains the extension specific protected settings.')
@secure()
param extensionCustomScriptProtectedSetting object = {}

// Shared parameters
@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.')
@minValue(0)
@maxValue(365)
param diagnosticLogsRetentionInDays int = 365

@description('Optional. Resource ID of the diagnostic storage account.')
param diagnosticStorageAccountId string = ''

@description('Optional. Resource ID of the diagnostic log analytics workspace.')
param diagnosticWorkspaceId string = ''

@description('Optional. Resource ID of the diagnostic event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.')
param diagnosticEventHubAuthorizationRuleId string = ''

@description('Optional. Name of the diagnostic event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category.')
param diagnosticEventHubName string = ''

@allowed([
  ''
  'CanNotDelete'
  'ReadOnly'
])
@description('Optional. Specify the type of lock.')
param lock string = ''

@description('Optional. Array of role assignment objects that contain the \'roleDefinitionIdOrName\' and \'principalId\' to define RBAC role assignments on this resource. In the roleDefinitionIdOrName attribute, you can provide either the display name of the role definition, or its fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.')
param roleAssignments array = []

@description('Optional. Tags of the resource.')
param tags object = {}

@description('Optional. Enable telemetry via a Globally Unique Identifier (GUID).')
param enableDefaultTelemetry bool = true

@description('Generated. Do not provide a value! This date value is used to generate a registration token.')
param baseTime string = utcNow('u')

@description('Optional. SAS token validity length to use to download files from storage accounts. Usage: \'PT8H\' - valid for 8 hours; \'P5D\' - valid for 5 days; \'P1Y\' - valid for 1 year. When not provided, the SAS token will be valid for 8 hours.')
param sasTokenValidityLength string = 'PT8H'

@description('Required. The chosen OS type.')
@allowed([
  'Windows'
  'Linux'
])
param osType string

@description('Optional. Specifies whether password authentication should be disabled.')
#disable-next-line secure-secrets-in-params // Not a secret
param disablePasswordAuthentication bool = false

@description('Optional. Indicates whether virtual machine agent should be provisioned on the virtual machine. When this property is not specified in the request body, default behavior is to set it to true. This will ensure that VM Agent is installed on the VM so that extensions can be added to the VM later.')
param provisionVMAgent bool = true

@description('Optional. Indicates whether Automatic Updates is enabled for the Windows virtual machine. Default value is true. When patchMode is set to Manual, this parameter must be set to false. For virtual machine scale sets, this property can be updated and updates will take effect on OS reprovisioning.')
param enableAutomaticUpdates bool = true

@description('Optional. VM guest patching orchestration mode. \'AutomaticByOS\' & \'Manual\' are for Windows only, \'ImageDefault\' for Linux only. Refer to \'https://learn.microsoft.com/en-us/azure/virtual-machines/automatic-vm-guest-patching\'.')
@allowed([
  'AutomaticByPlatform'
  'AutomaticByOS'
  'Manual'
  'ImageDefault'
  ''
])
param patchMode string = ''

@description('Optional. VM guest patching assessment mode. Set it to \'AutomaticByPlatform\' to enable automatically check for updates every 24 hours.')
@allowed([
  'AutomaticByPlatform'
  'ImageDefault'
])
param patchAssessmentMode string = 'ImageDefault'

@description('Optional. Specifies the time zone of the virtual machine. e.g. \'Pacific Standard Time\'. Possible values can be `TimeZoneInfo.id` value from time zones returned by `TimeZoneInfo.GetSystemTimeZones`.')
param timeZone string = ''

@description('Optional. Specifies additional base-64 encoded XML formatted information that can be included in the Unattend.xml file, which is used by Windows Setup. - AdditionalUnattendContent object.')
param additionalUnattendContent array = []

@description('Optional. Specifies the Windows Remote Management listeners. This enables remote Windows PowerShell. - WinRMConfiguration object.')
param winRM object = {}

@description('Required. The configuration profile of automanage.')
@allowed([
  '/providers/Microsoft.Automanage/bestPractices/AzureBestPracticesProduction'
  '/providers/Microsoft.Automanage/bestPractices/AzureBestPracticesDevTest'
  ''
])
param configurationProfile string = ''

var vmComputerNameTransformed = vmComputerNamesTransformation == 'uppercase' ? toUpper(name) : (vmComputerNamesTransformation == 'lowercase' ? toLower(name) : name)

var publicKeysFormatted = [for publicKey in publicKeys: {
  path: publicKey.path
  keyData: publicKey.keyData
}]

var linuxConfiguration = {
  disablePasswordAuthentication: disablePasswordAuthentication
  ssh: {
    publicKeys: publicKeysFormatted
  }
  provisionVMAgent: provisionVMAgent
  patchSettings: (provisionVMAgent && (patchMode =~ 'AutomaticByPlatform' || patchMode =~ 'ImageDefault')) ? {
    patchMode: patchMode
    assessmentMode: patchAssessmentMode
  } : null
}

var windowsConfiguration = {
  provisionVMAgent: provisionVMAgent
  enableAutomaticUpdates: enableAutomaticUpdates
  patchSettings: (provisionVMAgent && (patchMode =~ 'AutomaticByPlatform' || patchMode =~ 'AutomaticByOS' || patchMode =~ 'Manual')) ? {
    patchMode: patchMode
    assessmentMode: patchAssessmentMode
  } : null
  timeZone: empty(timeZone) ? null : timeZone
  additionalUnattendContent: empty(additionalUnattendContent) ? null : additionalUnattendContent
  winRM: !empty(winRM) ? {
    listeners: winRM
  } : null
}

var accountSasProperties = {
  signedServices: 'b'
  signedPermission: 'r'
  signedExpiry: dateTimeAdd(baseTime, sasTokenValidityLength)
  signedResourceTypes: 'o'
  signedProtocol: 'https'
}

/* Determine Identity Type.
  First, we determine if the System-Assigned Managed Identity should be enabled.
    If AADJoin Extension is enabled then we automatically add SystemAssigned to the identityType because AADJoin requires the System-Assigned Managed Identity.
    If the AADJoin Extension is not enabled then we add SystemAssigned to the identityType only if the value of the systemAssignedIdentity parameter is true.
  Second, we determine if User Assigned Identities are assigned to the VM via the userAssignedIdentities parameter.
  Third, we take the outcome of these two values and determine the identityType
    If the System Identity and User Identities are assigned then the identityType is 'SystemAssigned,UserAssigned'
    If only the system Identity is assigned then the identityType is 'SystemAssigned'
    If only user managed Identities are assigned, then the identityType is 'UserAssigned'
    Finally, if no identities are assigned, then the identityType is 'none'.
*/
var identityType = (extensionAadJoinConfig.enabled ? true : systemAssignedIdentity) ? (!empty(userAssignedIdentities) ? 'SystemAssigned,UserAssigned' : 'SystemAssigned') : (!empty(userAssignedIdentities) ? 'UserAssigned' : 'None')

var identity = identityType != 'None' ? {
  type: identityType
  userAssignedIdentities: !empty(userAssignedIdentities) ? userAssignedIdentities : null
} : null

var enableReferencedModulesTelemetry = false

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

module vm_nic '.bicep/nested_networkInterface.bicep' = [for (nicConfiguration, index) in nicConfigurations: {
  name: '${uniqueString(deployment().name, location)}-VM-Nic-${index}'
  params: {
    networkInterfaceName: '${name}${nicConfiguration.nicSuffix}'
    virtualMachineName: name
    location: location
    tags: tags
    enableIPForwarding: contains(nicConfiguration, 'enableIPForwarding') ? (!empty(nicConfiguration.enableIPForwarding) ? nicConfiguration.enableIPForwarding : false) : false
    enableAcceleratedNetworking: contains(nicConfiguration, 'enableAcceleratedNetworking') ? nicConfiguration.enableAcceleratedNetworking : true
    dnsServers: contains(nicConfiguration, 'dnsServers') ? (!empty(nicConfiguration.dnsServers) ? nicConfiguration.dnsServers : []) : []
    networkSecurityGroupResourceId: contains(nicConfiguration, 'networkSecurityGroupResourceId') ? nicConfiguration.networkSecurityGroupResourceId : ''
    ipConfigurations: nicConfiguration.ipConfigurations
    lock: lock
    diagnosticStorageAccountId: diagnosticStorageAccountId
    diagnosticLogsRetentionInDays: diagnosticLogsRetentionInDays
    diagnosticWorkspaceId: diagnosticWorkspaceId
    diagnosticEventHubAuthorizationRuleId: diagnosticEventHubAuthorizationRuleId
    diagnosticEventHubName: diagnosticEventHubName
    pipDiagnosticSettingsName: pipDiagnosticSettingsName
    nicDiagnosticSettingsName: nicDiagnosticSettingsName
    pipdiagnosticMetricsToEnable: pipdiagnosticMetricsToEnable
    pipdiagnosticLogCategoriesToEnable: pipdiagnosticLogCategoriesToEnable
    nicDiagnosticMetricsToEnable: nicdiagnosticMetricsToEnable
    roleAssignments: contains(nicConfiguration, 'roleAssignments') ? (!empty(nicConfiguration.roleAssignments) ? nicConfiguration.roleAssignments : []) : []
  }
}]

resource vm 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  name: name
  location: location
  identity: identity
  tags: tags
  zones: availabilityZone != 0 ? array(availabilityZone) : null
  plan: !empty(plan) ? plan : null
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    securityProfile: {
      encryptionAtHost: encryptionAtHost ? encryptionAtHost : null
      securityType: securityType
      uefiSettings: securityType == 'TrustedLaunch' ? {
        secureBootEnabled: secureBootEnabled
        vTpmEnabled: vTpmEnabled
      } : null
    }
    storageProfile: {
      imageReference: imageReference
      osDisk: {
        name: '${name}-disk-os-01'
        createOption: contains(osDisk, 'createOption') ? osDisk.createOption : 'FromImage'
        deleteOption: contains(osDisk, 'deleteOption') ? osDisk.deleteOption : 'Delete'
        diskSizeGB: osDisk.diskSizeGB
        caching: contains(osDisk, 'caching') ? osDisk.caching : 'ReadOnly'
        managedDisk: {
          storageAccountType: osDisk.managedDisk.storageAccountType
          diskEncryptionSet: contains(osDisk.managedDisk, 'diskEncryptionSet') ? {
            id: osDisk.managedDisk.diskEncryptionSet.id
          } : null
        }
      }
      dataDisks: [for (dataDisk, index) in dataDisks: {
        lun: index
        name: '${name}-disk-data-${padLeft((index + 1), 2, '0')}'
        diskSizeGB: dataDisk.diskSizeGB
        createOption: contains(dataDisk, 'createOption') ? dataDisk.createOption : 'Empty'
        deleteOption: contains(dataDisk, 'deleteOption') ? dataDisk.deleteOption : 'Delete'
        caching: contains(dataDisk, 'caching') ? dataDisk.caching : 'ReadOnly'
        managedDisk: {
          storageAccountType: dataDisk.managedDisk.storageAccountType
          diskEncryptionSet: contains(dataDisk.managedDisk, 'diskEncryptionSet') ? {
            id: dataDisk.managedDisk.diskEncryptionSet.id
          } : null
        }
      }]
    }
    additionalCapabilities: {
      ultraSSDEnabled: ultraSSDEnabled
    }
    osProfile: {
      computerName: vmComputerNameTransformed
      adminUsername: adminUsername
      adminPassword: adminPassword
      customData: !empty(customData) ? base64(customData) : null
      windowsConfiguration: osType == 'Windows' ? windowsConfiguration : null
      linuxConfiguration: osType == 'Linux' ? linuxConfiguration : null
      secrets: certificatesToBeInstalled
      allowExtensionOperations: allowExtensionOperations
    }
    networkProfile: {
      networkInterfaces: [for (nicConfiguration, index) in nicConfigurations: {
        properties: {
          deleteOption: contains(nicConfiguration, 'deleteOption') ? nicConfiguration.deleteOption : 'Delete'
          primary: index == 0 ? true : false
        }
        id: az.resourceId('Microsoft.Network/networkInterfaces', '${name}${nicConfiguration.nicSuffix}')
      }]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: !empty(bootDiagnosticStorageAccountName) ? true : bootDiagnostics
        storageUri: !empty(bootDiagnosticStorageAccountName) ? 'https://${bootDiagnosticStorageAccountName}${bootDiagnosticStorageAccountUri}' : null
      }
    }
    availabilitySet: !empty(availabilitySetResourceId) ? {
      id: availabilitySetResourceId
    } : null
    proximityPlacementGroup: !empty(proximityPlacementGroupResourceId) ? {
      id: proximityPlacementGroupResourceId
    } : null
    priority: vmPriority
    evictionPolicy: enableEvictionPolicy ? 'Deallocate' : null
    billingProfile: !empty(vmPriority) && !empty(maxPriceForLowPriorityVm) ? {
      maxPrice: maxPriceForLowPriorityVm
    } : null
    host: !empty(dedicatedHostId) ? {
      id: dedicatedHostId
    } : null
    licenseType: !empty(licenseType) ? licenseType : null
  }
  dependsOn: [
    vm_nic
  ]
}

resource vm_configurationProfileAssignment 'Microsoft.Automanage/configurationProfileAssignments@2021-04-30-preview' = if (!empty(configurationProfile)) {
  name: 'default'
  properties: {
    configurationProfile: configurationProfile
  }
  scope: vm
}

module vm_aadJoinExtension 'extensions/deploy.bicep' = if (extensionAadJoinConfig.enabled) {
  name: '${uniqueString(deployment().name, location)}-VM-AADLogin'
  params: {
    virtualMachineName: vm.name
    name: 'AADLogin'
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: osType == 'Windows' ? 'AADLoginForWindows' : 'AADSSHLoginforLinux'
    typeHandlerVersion: contains(extensionAadJoinConfig, 'typeHandlerVersion') ? extensionAadJoinConfig.typeHandlerVersion : '1.0'
    autoUpgradeMinorVersion: contains(extensionAadJoinConfig, 'autoUpgradeMinorVersion') ? extensionAadJoinConfig.autoUpgradeMinorVersion : true
    enableAutomaticUpgrade: contains(extensionAadJoinConfig, 'enableAutomaticUpgrade') ? extensionAadJoinConfig.enableAutomaticUpgrade : false
    settings: contains(extensionAadJoinConfig, 'settings') ? extensionAadJoinConfig.settings : null
  }
}

module vm_domainJoinExtension 'extensions/deploy.bicep' = if (extensionDomainJoinConfig.enabled) {
  name: '${uniqueString(deployment().name, location)}-VM-DomainJoin'
  params: {
    virtualMachineName: vm.name
    name: 'DomainJoin'
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: contains(extensionDomainJoinConfig, 'typeHandlerVersion') ? extensionDomainJoinConfig.typeHandlerVersion : '1.3'
    autoUpgradeMinorVersion: contains(extensionDomainJoinConfig, 'autoUpgradeMinorVersion') ? extensionDomainJoinConfig.autoUpgradeMinorVersion : true
    enableAutomaticUpgrade: contains(extensionDomainJoinConfig, 'enableAutomaticUpgrade') ? extensionDomainJoinConfig.enableAutomaticUpgrade : false
    settings: extensionDomainJoinConfig.settings
    protectedSettings: {
      Password: extensionDomainJoinPassword
    }
    enableDefaultTelemetry: enableReferencedModulesTelemetry
  }
}

module vm_microsoftAntiMalwareExtension 'extensions/deploy.bicep' = if (extensionAntiMalwareConfig.enabled) {
  name: '${uniqueString(deployment().name, location)}-VM-MicrosoftAntiMalware'
  params: {
    virtualMachineName: vm.name
    name: 'MicrosoftAntiMalware'
    publisher: 'Microsoft.Azure.Security'
    type: 'IaaSAntimalware'
    typeHandlerVersion: contains(extensionAntiMalwareConfig, 'typeHandlerVersion') ? extensionAntiMalwareConfig.typeHandlerVersion : '1.3'
    autoUpgradeMinorVersion: contains(extensionAntiMalwareConfig, 'autoUpgradeMinorVersion') ? extensionAntiMalwareConfig.autoUpgradeMinorVersion : true
    enableAutomaticUpgrade: contains(extensionAntiMalwareConfig, 'enableAutomaticUpgrade') ? extensionAntiMalwareConfig.enableAutomaticUpgrade : false
    settings: extensionAntiMalwareConfig.settings
    enableDefaultTelemetry: enableReferencedModulesTelemetry
  }
}

resource vm_logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = if (!empty(monitoringWorkspaceId)) {
  name: last(split(monitoringWorkspaceId, '/'))
  scope: az.resourceGroup(split(monitoringWorkspaceId, '/')[2], split(monitoringWorkspaceId, '/')[4])
}

module vm_microsoftMonitoringAgentExtension 'extensions/deploy.bicep' = if (extensionMonitoringAgentConfig.enabled) {
  name: '${uniqueString(deployment().name, location)}-VM-MicrosoftMonitoringAgent'
  params: {
    virtualMachineName: vm.name
    name: 'MicrosoftMonitoringAgent'
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: osType == 'Windows' ? 'MicrosoftMonitoringAgent' : 'OmsAgentForLinux'
    typeHandlerVersion: contains(extensionMonitoringAgentConfig, 'typeHandlerVersion') ? extensionMonitoringAgentConfig.typeHandlerVersion : (osType == 'Windows' ? '1.0' : '1.7')
    autoUpgradeMinorVersion: contains(extensionMonitoringAgentConfig, 'autoUpgradeMinorVersion') ? extensionMonitoringAgentConfig.autoUpgradeMinorVersion : true
    enableAutomaticUpgrade: contains(extensionMonitoringAgentConfig, 'enableAutomaticUpgrade') ? extensionMonitoringAgentConfig.enableAutomaticUpgrade : false
    settings: {
      workspaceId: !empty(monitoringWorkspaceId) ? reference(vm_logAnalyticsWorkspace.id, vm_logAnalyticsWorkspace.apiVersion).customerId : ''
    }
    protectedSettings: {
      workspaceKey: !empty(monitoringWorkspaceId) ? vm_logAnalyticsWorkspace.listKeys().primarySharedKey : ''
    }
    enableDefaultTelemetry: enableReferencedModulesTelemetry
  }
}

module vm_dependencyAgentExtension 'extensions/deploy.bicep' = if (extensionDependencyAgentConfig.enabled) {
  name: '${uniqueString(deployment().name, location)}-VM-DependencyAgent'
  params: {
    virtualMachineName: vm.name
    name: 'DependencyAgent'
    publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
    type: osType == 'Windows' ? 'DependencyAgentWindows' : 'DependencyAgentLinux'
    typeHandlerVersion: contains(extensionDependencyAgentConfig, 'typeHandlerVersion') ? extensionDependencyAgentConfig.typeHandlerVersion : '9.5'
    autoUpgradeMinorVersion: contains(extensionDependencyAgentConfig, 'autoUpgradeMinorVersion') ? extensionDependencyAgentConfig.autoUpgradeMinorVersion : true
    enableAutomaticUpgrade: contains(extensionDependencyAgentConfig, 'enableAutomaticUpgrade') ? extensionDependencyAgentConfig.enableAutomaticUpgrade : true
    enableDefaultTelemetry: enableReferencedModulesTelemetry
  }
}

module vm_networkWatcherAgentExtension 'extensions/deploy.bicep' = if (extensionNetworkWatcherAgentConfig.enabled) {
  name: '${uniqueString(deployment().name, location)}-VM-NetworkWatcherAgent'
  params: {
    virtualMachineName: vm.name
    name: 'NetworkWatcherAgent'
    publisher: 'Microsoft.Azure.NetworkWatcher'
    type: osType == 'Windows' ? 'NetworkWatcherAgentWindows' : 'NetworkWatcherAgentLinux'
    typeHandlerVersion: contains(extensionNetworkWatcherAgentConfig, 'typeHandlerVersion') ? extensionNetworkWatcherAgentConfig.typeHandlerVersion : '1.4'
    autoUpgradeMinorVersion: contains(extensionNetworkWatcherAgentConfig, 'autoUpgradeMinorVersion') ? extensionNetworkWatcherAgentConfig.autoUpgradeMinorVersion : true
    enableAutomaticUpgrade: contains(extensionNetworkWatcherAgentConfig, 'enableAutomaticUpgrade') ? extensionNetworkWatcherAgentConfig.enableAutomaticUpgrade : false
    enableDefaultTelemetry: enableReferencedModulesTelemetry
  }
}

module vm_desiredStateConfigurationExtension 'extensions/deploy.bicep' = if (extensionDSCConfig.enabled) {
  name: '${uniqueString(deployment().name, location)}-VM-DesiredStateConfiguration'
  params: {
    virtualMachineName: vm.name
    name: 'DesiredStateConfiguration'
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: contains(extensionDSCConfig, 'typeHandlerVersion') ? extensionDSCConfig.typeHandlerVersion : '2.77'
    autoUpgradeMinorVersion: contains(extensionDSCConfig, 'autoUpgradeMinorVersion') ? extensionDSCConfig.autoUpgradeMinorVersion : true
    enableAutomaticUpgrade: contains(extensionDSCConfig, 'enableAutomaticUpgrade') ? extensionDSCConfig.enableAutomaticUpgrade : false
    settings: contains(extensionDSCConfig, 'settings') ? extensionDSCConfig.settings : {}
    protectedSettings: contains(extensionDSCConfig, 'protectedSettings') ? extensionDSCConfig.protectedSettings : {}
    enableDefaultTelemetry: enableReferencedModulesTelemetry
  }
}

module vm_customScriptExtension 'extensions/deploy.bicep' = if (extensionCustomScriptConfig.enabled) {
  name: '${uniqueString(deployment().name, location)}-VM-CustomScriptExtension'
  params: {
    virtualMachineName: vm.name
    name: 'CustomScriptExtension'
    publisher: osType == 'Windows' ? 'Microsoft.Compute' : 'Microsoft.Azure.Extensions'
    type: osType == 'Windows' ? 'CustomScriptExtension' : 'CustomScript'
    typeHandlerVersion: contains(extensionCustomScriptConfig, 'typeHandlerVersion') ? extensionCustomScriptConfig.typeHandlerVersion : (osType == 'Windows' ? '1.10' : '2.1')
    autoUpgradeMinorVersion: contains(extensionCustomScriptConfig, 'autoUpgradeMinorVersion') ? extensionCustomScriptConfig.autoUpgradeMinorVersion : true
    enableAutomaticUpgrade: contains(extensionCustomScriptConfig, 'enableAutomaticUpgrade') ? extensionCustomScriptConfig.enableAutomaticUpgrade : false
    settings: {
      fileUris: [for fileData in extensionCustomScriptConfig.fileData: contains(fileData, 'storageAccountId') ? '${fileData.uri}?${listAccountSas(fileData.storageAccountId, '2019-04-01', accountSasProperties).accountSasToken}' : fileData.uri]
    }
    protectedSettings: extensionCustomScriptProtectedSetting
    enableDefaultTelemetry: enableReferencedModulesTelemetry
  }
  dependsOn: [
    vm_desiredStateConfigurationExtension
  ]
}

module vm_azureDiskEncryptionExtension 'extensions/deploy.bicep' = if (extensionAzureDiskEncryptionConfig.enabled) {
  name: '${uniqueString(deployment().name, location)}-VM-AzureDiskEncryption'
  params: {
    virtualMachineName: vm.name
    name: 'AzureDiskEncryption'
    publisher: 'Microsoft.Azure.Security'
    type: osType == 'Windows' ? 'AzureDiskEncryption' : 'AzureDiskEncryptionForLinux'
    typeHandlerVersion: contains(extensionAzureDiskEncryptionConfig, 'typeHandlerVersion') ? extensionAzureDiskEncryptionConfig.typeHandlerVersion : (osType == 'Windows' ? '2.2' : '1.1')
    autoUpgradeMinorVersion: contains(extensionAzureDiskEncryptionConfig, 'autoUpgradeMinorVersion') ? extensionAzureDiskEncryptionConfig.autoUpgradeMinorVersion : true
    enableAutomaticUpgrade: contains(extensionAzureDiskEncryptionConfig, 'enableAutomaticUpgrade') ? extensionAzureDiskEncryptionConfig.enableAutomaticUpgrade : false
    forceUpdateTag: contains(extensionAzureDiskEncryptionConfig, 'forceUpdateTag') ? extensionAzureDiskEncryptionConfig.forceUpdateTag : '1.0'
    settings: extensionAzureDiskEncryptionConfig.settings
    enableDefaultTelemetry: enableReferencedModulesTelemetry
  }
  dependsOn: [
    vm_customScriptExtension
    vm_microsoftMonitoringAgentExtension
  ]
}

module vm_backup '../../Microsoft.RecoveryServices/vaults/protectionContainers/protectedItems/deploy.bicep' = if (!empty(backupVaultName)) {
  name: '${uniqueString(deployment().name, location)}-VM-Backup'
  params: {
    name: 'vm;iaasvmcontainerv2;${resourceGroup().name};${vm.name}'
    policyId: az.resourceId('Microsoft.RecoveryServices/vaults/backupPolicies', backupVaultName, backupPolicyName)
    protectedItemType: 'Microsoft.Compute/virtualMachines'
    protectionContainerName: 'iaasvmcontainer;iaasvmcontainerv2;${resourceGroup().name};${vm.name}'
    recoveryVaultName: backupVaultName
    sourceResourceId: vm.id
    enableDefaultTelemetry: enableReferencedModulesTelemetry
  }
  scope: az.resourceGroup(backupVaultResourceGroup)
  dependsOn: [
    vm_aadJoinExtension
    vm_domainJoinExtension
    vm_microsoftMonitoringAgentExtension
    vm_microsoftAntiMalwareExtension
    vm_networkWatcherAgentExtension
    vm_dependencyAgentExtension
    vm_desiredStateConfigurationExtension
    vm_customScriptExtension
  ]
}

resource vm_lock 'Microsoft.Authorization/locks@2020-05-01' = if (!empty(lock)) {
  name: '${vm.name}-${lock}-lock'
  properties: {
    level: any(lock)
    notes: lock == 'CanNotDelete' ? 'Cannot delete resource or child resources.' : 'Cannot modify the resource or child resources.'
  }
  scope: vm
}

module vm_roleAssignments '.bicep/nested_roleAssignments.bicep' = [for (roleAssignment, index) in roleAssignments: {
  name: '${uniqueString(deployment().name, location)}-VM-Rbac-${index}'
  params: {
    description: contains(roleAssignment, 'description') ? roleAssignment.description : ''
    principalIds: roleAssignment.principalIds
    principalType: contains(roleAssignment, 'principalType') ? roleAssignment.principalType : ''
    roleDefinitionIdOrName: roleAssignment.roleDefinitionIdOrName
    condition: contains(roleAssignment, 'condition') ? roleAssignment.condition : ''
    delegatedManagedIdentityResourceId: contains(roleAssignment, 'delegatedManagedIdentityResourceId') ? roleAssignment.delegatedManagedIdentityResourceId : ''
    resourceId: vm.id
  }
}]

@description('The name of the VM.')
output name string = vm.name

@description('The resource ID of the VM.')
output resourceId string = vm.id

@description('The name of the resource group the VM was created in.')
output resourceGroupName string = resourceGroup().name

@description('The principal ID of the system assigned identity.')
output systemAssignedPrincipalId string = systemAssignedIdentity && contains(vm.identity, 'principalId') ? vm.identity.principalId : ''

@description('The location the resource was deployed into.')
output location string = vm.location
