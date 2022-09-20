﻿#region Helper functions
<#
.SYNOPSIS
Replace tokens like '<<ProviderNamespace>>' in the given file with an actual value

.DESCRIPTION
Replace tokens like '<<ProviderNamespace>>' in the given file with an actual value. Tokens that are replaced:
- <<providerNamespace>>
- <<shortProviderNamespacePascal>>
- <<shortProviderNamespaceLower>>
- <<resourceType>>
- <<resourceTypePascal>>
- <<resourceTypeLower>>

.PARAMETER Content
Mandatory. The content to update

.PARAMETER ProviderNamespace
Mandatory. The Provider Namespace to replaces tokens for

.PARAMETER ResourceType
Mandatory. The Resource Type to replaces tokens for

.EXAMPLE
Format-AutomationTemplate -Content "Hello <<shortProviderNamespaceLower>>-<<resourceTypePascal>>" -ProviderNamespace 'Microsoft.KeyVault' -ResourceType 'vaults'

Update the provided content with different Provider Namespace & Resource Type token variant. Would return 'Hello keyvault-Vaults'
#>
function Format-AutomationTemplate {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Content,

        [Parameter(Mandatory)]
        [string] $ProviderNamespace,

        [Parameter(Mandatory)]
        [string] $ResourceType
    )

    begin {
        Write-Debug ('{0} entered' -f $MyInvocation.MyCommand)
    }

    process {
        $tokens = @{
            providerNamespace            = $ProviderNamespace
            shortProviderNamespacePascal = ($ProviderNamespace -split '\.')[-1].substring(0, 1).toupper() + ($ProviderNamespace -split '\.')[-1].substring(1)
            shortProviderNamespaceLower  = ($ProviderNamespace -split '\.')[-1].ToLower()
            resourceType                 = $ResourceType
            resourceTypePascal           = $ResourceType.substring(0, 1).toupper() + $ResourceType.substring(1)
            resourceTypeLower            = $ResourceType.ToLower()
        }

        foreach ($token in $tokens.Keys) {
            $content = $content -replace "<<$token>>", $tokens[$token]
        }

        return $content
    }

    end {
        Write-Debug ('{0} exited' -f $MyInvocation.MyCommand)
    }
}
#endregion

<#
.SYNOPSIS
Update / create the initial folder structure for a CARML module

.DESCRIPTION
Update / create the initial folder structure for a CARML module

.PARAMETER ProviderNamespace
Mandatory. The Provider Namespace to process

.PARAMETER ResourceType
Mandatory. The Resource Type to process

.EXAMPLE
Set-ModuleFileStructure -ProviderNamespace 'Microsoft.KeyVault' -ResourceType 'vaults'

Update / create the folder & file structure for the CARML module 'Microsoft.KeyVault/vaults'.
#>
function Set-ModuleFileStructure {

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string] $ProviderNamespace,

        [Parameter(Mandatory)]
        [string] $ResourceType
    )

    begin {
        Write-Debug ('{0} entered' -f $MyInvocation.MyCommand)
        $repoRootPath = (Get-Item $PSScriptRoot).Parent.Parent.Parent
    }

    process {
        # Create folders
        # --------------
        $expectedModuleFolderPath = Join-Path $repoRootPath 'modules' $ProviderNamespace $ResourceType
        @(
            $expectedModuleFolderPath,
            (Join-Path $expectedModuleFolderPath '.bicep'),
            (Join-Path $expectedModuleFolderPath '.test')
            (Join-Path $expectedModuleFolderPath '.test' 'common')
            (Join-Path $expectedModuleFolderPath '.test' 'min')
        ) | ForEach-Object {
            if (-not (Test-Path $_)) {
                if ($PSCmdlet.ShouldProcess(('Folder [{0}]' -f ($_ -replace ($repoRootPath -replace '\\', '\\'), '')), 'Create')) {
                    $null = New-Item -Path $_ -ItemType 'Directory'
                }
            } else {
                Write-Verbose "Folder [$_] already exists."
            }
        }

        # Create module files
        # -------------------
        ## Root files
        ### Template file
        $templateFilePath = Join-Path $expectedModuleFolderPath 'deploy.bicep'
        if (-not (Test-Path $templateFilePath)) {
            if ($PSCmdlet.ShouldProcess(('Template file [{0}]' -f ($templateFilePath -replace ($repoRootPath -replace '\\', '\\'), '')), 'Create')) {
                $null = New-Item -Path $templateFilePath -ItemType 'File'
            }
        } else {
            Write-Verbose ('Template file [{0}] already exists.' -f ($templateFilePath -replace ($repoRootPath -replace '\\', '\\'), ''))
        }

        ### Version file
        $versionFilePath = Join-Path $expectedModuleFolderPath 'version.json'
        if (-not (Test-Path $versionFilePath)) {
            if ($PSCmdlet.ShouldProcess(('Version file [{0}]' -f ($versionFilePath -replace ($repoRootPath -replace '\\', '\\'), '')), 'Create')) {
                $versionFileContent = Get-Content (Join-Path $PSScriptRoot 'src' 'moduleVersion.json') -Raw
                $null = New-Item -Path $versionFilePath -ItemType 'File' -Value $versionFileContent
            }
        } else {
            Write-Verbose ('Version file [{0}] already exists.' -f ($versionFilePath -replace ($repoRootPath -replace '\\', '\\'), ''))
        }

        ### ReadMe file
        $readMeFilePath = Join-Path $expectedModuleFolderPath 'readme.md'
        if (-not (Test-Path $readMeFilePath)) {
            if ($PSCmdlet.ShouldProcess(('ReadMe file [{0}]' -f ($readMeFilePath -replace ($repoRootPath -replace '\\', '\\'), '')), 'Create')) {
                $null = New-Item -Path $readMeFilePath -ItemType 'File'
            }
        } else {
            Write-Verbose ('ReadMe file [{0}] already exists.' -f ($readMeFilePath -replace ($repoRootPath -replace '\\', '\\'), ''))
        }

        ## .test files
        @(
            (Join-Path $expectedModuleFolderPath '.test' 'common' 'deploy.bicep')
            (Join-Path $expectedModuleFolderPath '.test' 'min' 'deploy.bicep')
        ) | ForEach-Object {
            if (-not (Test-Path $_)) {
                if ($PSCmdlet.ShouldProcess(('File [{0}]' -f ($_ -replace ($repoRootPath -replace '\\', '\\'), '')), 'Create')) {
                    $null = New-Item -Path $_ -ItemType 'File'
                }
            } else {
                Write-Verbose "File [$_] already exists."
            }
        }

        # Create/Update DevOps files
        # --------------------------
        ## GitHub
        $automationFileName = ('ms.{0}.{1}.yml' -f ($ProviderNamespace -split '\.')[-1], $ResourceType).ToLower()
        $gitHubWorkflowYAMLPath = Join-Path $repoRootPath '.github' 'workflows' $automationFileName
        $workflowFileContent = Get-Content (Join-Path $PSScriptRoot 'src' 'gitHubWorkflowTemplateFile.yml') -Raw
        $workflowFileContent = Format-AutomationTemplate -Content $workflowFileContent -ProviderNamespace $ProviderNamespace -ResourceType $ResourceType
        if (-not (Test-Path $gitHubWorkflowYAMLPath)) {
            if ($PSCmdlet.ShouldProcess("GitHub Workflow file [$automationFileName]", 'Create')) {
                $null = New-Item $gitHubWorkflowYAMLPath -ItemType 'File' -Value $workflowFileContent.TrimEnd()
            }
        } else {
            if ($PSCmdlet.ShouldProcess("GitHub Workflow file [$automationFileName]", 'Update')) {
                $null = Set-Content -Path $gitHubWorkflowYAMLPath -Value $workflowFileContent.TrimEnd()
            }
        }

        ## Azure DevOps
        $azureDevOpsPipelineYAMLPath = Join-Path $repoRootPath '.azuredevops' 'modulePipelines' $automationFileName
        $pipelineFileContent = Get-Content (Join-Path $PSScriptRoot 'src' 'azureDevOpsPipelineTemplateFile.yml') -Raw
        $pipelineFileContent = Format-AutomationTemplate -Content $pipelineFileContent -ProviderNamespace $ProviderNamespace -ResourceType $ResourceType
        if (-not (Test-Path $azureDevOpsPipelineYAMLPath)) {
            if ($PSCmdlet.ShouldProcess("GitHub Workflow file [$automationFileName]", 'Create')) {
                $null = New-Item $azureDevOpsPipelineYAMLPath -ItemType 'File' -Value $pipelineFileContent.TrimEnd()
            }
        } else {
            if ($PSCmdlet.ShouldProcess("GitHub Workflow file [$automationFileName]", 'Update')) {
                $null = Set-Content -Path $azureDevOpsPipelineYAMLPath -Value $pipelineFileContent.TrimEnd()
            }
        }
    }

    end {
        Write-Debug ('{0} exited' -f $MyInvocation.MyCommand)
    }
}
