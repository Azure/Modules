﻿<#
.SYNOPSIS
Update the module's primary template (deploy.bicep) as per the provided module data.

.DESCRIPTION
Update the module's primary template (deploy.bicep) as per the provided module data.

.PARAMETER ProviderNamespace
Mandatory. The ProviderNamespace to update the template for.

.PARAMETER ResourceType
Mandatory. The ResourceType to update the template for.

.PARAMETER ModuleData
Mandatory. The module data (e.g. parameters) to add to the template.

.PARAMETER JSONFilePath
Mandatory. The service specification file to process.

.PARAMETER UrlPath
Mandatory. The API Path in the JSON specification file to process

.EXAMPLE
Set-ModuleTemplate -ProviderNamespace 'Microsoft.KeyVault' -ResourceType 'vaults' -ModuleData @{ parameters = @(...); resource = @(...); (...) } -JSONFilePath '(...)/resource-manager/Microsoft.KeyVault/stable/2022-07-01/keyvault.json' -UrlPath '/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.KeyVault/vaults/{vaultName}'

Update the module [Microsoft.KeyVault/vaults] with the provided module data.
#>
function Set-ModuleTemplate {

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $true)]
        [string] $ProviderNamespace,

        [Parameter(Mandatory = $true)]
        [string] $ResourceType,

        [Parameter(Mandatory = $true)]
        [array] $ModuleData,

        [Parameter(Mandatory = $true)]
        [string] $JSONFilePath,

        [Parameter(Mandatory = $true)]
        [string] $UrlPath
    )

    begin {
        Write-Debug ('{0} entered' -f $MyInvocation.MyCommand)

        $templatePath = Join-Path $script:repoRoot 'modules' $ProviderNamespace $ResourceType 'deploy.bicep'
    }

    process {

        $resourceTypeSingular = Get-ResourceTypeSingularName -ResourceType $ResourceType

        ##################
        ##  PARAMETERS  ##
        ##################

        $targetScope = Get-TargetScope -UrlPath $UrlPath

        $templateContent = @(
            "targetScope = '{0}'" -f $targetScope
            ''
            '// ============== //'
            '//   Parameters   //'
            '// ============== //'
            ''
        )

        # Add primary (service) parameters
        foreach ($parameter in $ModuleData.parameters) {
            $templateContent += Get-FormattedModuleParameter -ParameterData $parameter
        }
        # Add additional (extension) parameters
        foreach ($parameter in $ModuleData.additionalParameters) {
            $templateContent += Get-FormattedModuleParameter -ParameterData $parameter
        }
        # Add telemetry parameter
        $templateContent += Get-FormattedModuleParameter -ParameterData @{
            level       = 0
            name        = 'enableDefaultTelemetry'
            type        = 'bool'
            default     = $true
            description = 'Enable telemetry via the Customer Usage Attribution ID (GUID).'
            required    = $false
        }

        #################
        ##  VARIABLES  ##
        #################

        foreach ($variable in $ModuleData.variables) {
            $templateContent += $variable
        }
        # Add telemetry variable
        # TODO: Should only be added if module has children)
        $templateContent += @(
            'var enableReferencedModulesTelemetry = false'
            ''
        )

        ###################
        ##  DEPLOYMENTS  ##
        ###################

        $templateContent += @(
            ''
            '// =============== //'
            '//   Deployments   //'
            '// =============== //'
            ''
        )

        # Telemetry
        $templateContent += Get-Content -Path (Join-Path $Script:src 'telemetry.bicep')
        $templateContent += ''

        # Deployment resource declaration line
        $serviceAPIVersion = Split-Path (Split-Path $JSONFilePath -Parent) -Leaf
        $templateContent += "resource $resourceTypeSingular '$ProviderNamespace/$ResourceType@$serviceAPIVersion' = {"

        foreach ($parameter in ($ModuleData.parameters | Where-Object { $_.level -eq 0 })) {
            $templateContent += '  {0}: {0}' -f $parameter.name
        }

        $templateContent += '  properties: {'
        foreach ($parameter in ($ModuleData.parameters | Where-Object { $_.level -eq 1 })) {
            $templateContent += '    {0}: {0}' -f $parameter.name
        }

        $templateContent += @(
            '  }'
            '}'
            ''
        )


        # Other collected resources
        $templateContent += $ModuleData.resources

        # TODO: Add children if applicable

        #######################################
        ##  Create template outputs section  ##
        #######################################

        # Output header comment
        $templateContent += @(
            '// =========== //'
            '//   Outputs   //'
            '// =========== //'
            ''
            "@description('The name of the $resourceTypeSingular.')"
            "output name string = $resourceTypeSingular.name"
            ''
            "@description('The resource ID of the $resourceTypeSingular.')"
            "output resourceId string = $resourceTypeSingular.id"
            ''
        )

        if ($targetScope -eq 'resourceGroup') {
            $templateContent += @(
                "@description('The name of the resource group the $resourceTypeSingular was created in.')"
                'output resourceGroupName string = resourceGroup().name'
                ''
            )
        }

        # Update file
        # -----------
        Set-Content -Path $templatePath -Value $templateContent.TrimEnd()
    }

    end {
        Write-Debug ('{0} exited' -f $MyInvocation.MyCommand)
    }
}
