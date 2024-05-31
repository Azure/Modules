# Note: The installation commands in this script are optimized for Linux

#region Helper Functions
<#
.SYNOPSIS
Installes given PowerShell modules

.DESCRIPTION
Installes given PowerShell modules

.PARAMETER Module
Required. Modules to be installed, must be Object
@{
    Name = 'Name'
    Version = '1.0.0' # Optional
}

.PARAMETER InstalledModule
Optional. Modules that are already installed on the machine. Can be fetched via 'Get-Module -ListAvailable'

.EXAMPLE
Install-CustomModule @{ Name = 'Pester' } C:\Modules

Installes pester and saves it to C:\Modules
#>
function Install-CustomModule {

    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [Parameter(Mandatory = $true)]
        [Hashtable] $Module,

        [Parameter(Mandatory = $false)]
        [object[]] $InstalledModule = @()
    )

    # Remove exsisting module in session
    if (Get-Module $Module -ErrorAction 'SilentlyContinue') {
        try {
            Remove-Module $Module -Force
        } catch {
            Write-Error ('Unable to remove module [{0}] because of exception [{1}]. Stack Trace: [{2}]' -f $Module.Name, $_.Exception, $_.ScriptStackTrace)
        }
    }

    # Install found module
    $moduleImportInputObject = @{
        name       = $Module.Name
        Repository = 'PSGallery'
    }
    if ($Module.Version) {
        $moduleImportInputObject['RequiredVersion'] = $Module.Version
    }

    # Get all modules that match a certain name. In case of e.g. 'Az' it returns several.
    $foundModules = Find-Module @moduleImportInputObject

    foreach ($foundModule in $foundModules) {

        # Check if already installed as required
        if ($alreadyInstalled = $InstalledModule | Where-Object { $_.Name -eq $Module.Name }) {
            if ($Module.Version) {
                $alreadyInstalled = $alreadyInstalled | Where-Object { $_.Version -eq $Module.Version }
            } else {
                # Get latest in case of multiple
                $alreadyInstalled = ($alreadyInstalled | Sort-Object -Property Version -Descending)[0]
            }
            Write-Verbose ('Module [{0}] already installed with version [{1}]' -f $alreadyInstalled.Name, $alreadyInstalled.Version) -Verbose
            continue
        }

        # Check if not to be excluded
        if ($Module.ExcludeModules -and $Module.excludeModules.contains($foundModule.Name)) {
            Write-Verbose ('Module {0} is configured to be ignored.' -f $foundModule.Name) -Verbose
            continue
        }

        Write-Verbose ('Install module [{0}] with version [{1}]' -f $foundModule.Name, $foundModule.Version) -Verbose
        if ($PSCmdlet.ShouldProcess('Module [{0}]' -f $foundModule.Name, 'Install')) {
            $foundModule | Install-Module -Force -SkipPublisherCheck -AllowClobber
            if ($installed = Get-Module -Name $foundModule.Name -ListAvailable) {
                Write-Verbose ('Module [{0}] is installed with version [{1}]' -f $installed.Name, $installed.Version) -Verbose
            } else {
                Write-Error ('Installation of module [{0}] failed' -f $foundModule.Name)
            }
        }
    }
}
#endregion

<#
.SYNOPSIS
Configure the current agent

.DESCRIPTION
Configure the current agent with e.g. the necessary PowerShell modules.

.PARAMETER PSModules
Optional. The PowerShell modules that should be installed on the agent.

@(
    @{ Name = 'Az.Accounts' },
    @{ Name = 'Az.Compute' },
    @{ Name = 'Az.Resources' },
    @{ Name = 'Az.ContainerRegistry' },
    @{ Name = 'Az.KeyVault' },
    @{ Name = 'Az.RecoveryServices' },
    @{ Name = 'Az.Monitor' },
    @{ Name = 'Az.CognitiveServices' },
    @{ Name = 'Az.OperationalInsights' },
    @{
        Name = 'Pester'
        Version = '5.3.1' # Version is optional
    }
)

.EXAMPLE
Set-EnvironmentOnAgent

Install the default PowerShell modules to configure the agent

.EXAMPLE
$modules = @(
    @{ Name = 'Az.Accounts' },
    @{ Name = 'Az.Resources' }
)
Set-EnvironmentOnAgent -PSModules $modules

Install the given PowerShell modules to configure the agent.
#>
function Set-EnvironmentOnAgent {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [Hashtable[]] $PSModules = @()
    )

    ############################
    ##   PowerShell version   ##
    ############################

    Write-Verbose 'Powershell version:' -Verbose
    $PSVersionTable

    # # Update the list of packages
    # sudo apt-get update
    # # Install pre-requisite packages.
    # sudo apt-get install -y wget apt-transport-https software-properties-common
    # # Download the Microsoft repository GPG keys
    # wget -q "https://packages.microsoft.com/config/ubuntu/`$(lsb_release -rs)/packages-microsoft-prod.deb"
    # # Register the Microsoft repository GPG keys
    # sudo dpkg -i packages-microsoft-prod.deb
    # # Update the list of packages after we added packages.microsoft.com
    # sudo apt-get update
    # # Install PowerShell
    # sudo apt-get install -y powershell

    ###########################
    ##   Install Azure CLI   ##
    ###########################

    # AzCLI is pre-installed on GitHub hosted runners.
    # https://github.com/actions/virtual-environments#available-environments

    Write-Verbose 'Az CLI version:' -Verbose
    az --version
    <#
    Write-Verbose ("Install azure cli start") -Verbose
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    Write-Verbose ("Install azure cli end") -Verbose
    #>

    ##############################
    ##   Install Bicep for CLI   #
    ##############################

    # Bicep CLI is pre-installed on GitHub hosted runners.
    # https://github.com/actions/virtual-environments#available-environments

    Write-Verbose 'Bicep CLI version:' -Verbose
    bicep --version
    <#
    Write-Verbose ("Install bicep start") -Verbose
    # Fetch the latest Bicep CLI binary
    curl -Lo bicep 'https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64'

    # Mark it as executable
    chmod +x ./bicep

    # Add bicep to your PATH (requires admin)
    sudo mv ./bicep /usr/local/bin/bicep
    Write-Verbose ("Install bicep end") -Verbose
    #>

    ###############################
    ##   Install Extensions CLI   #
    ###############################

    # Azure CLI extension for DevOps is pre-installed on GitHub hosted runners.
    # https://github.com/actions/virtual-environments#available-environments

    Write-Verbose 'AZ CLI extensions:' -Verbose
    az extension list | ConvertFrom-Json | Select-Object -Property 'name', 'version', 'preview', 'experimental'

    <#
    Write-Verbose ('Install cli exentions start') -Verbose
    $Extensions = @(
        'azure-devops'
    )
    foreach ($extension in $Extensions) {
        if ((az extension list-available -o json | ConvertFrom-Json).Name -notcontains $extension) {
            Write-Verbose "Adding CLI extension '$extension'" -Verbose
            az extension add --name $extension
        }
    }
    Write-Verbose ('Install cli exentions end') -Verbose
    #>

    ####################################
    ##   Install PowerShell Modules   ##
    ####################################

    $count = 1
    Write-Verbose ('Try installing:') -Verbose
    $PSModules | ForEach-Object {
        Write-Verbose ('- {0}. [{1}]' -f $count, $_.Name) -Verbose
        $count++
    }

    # MS-hosted agents have pre-installed modules in a specific path. Let's make them discoverable if available.
    # Always create the $profile if it does not exist (to avoid later need of case handling)
    if (-not (Test-Path $profile)) {
        $null = New-Item -Path $profile -Force
    }
    if ((Test-Path '/usr/share/') -and ((Get-ChildItem -Path '/usr/share/az_*' -Directory).Count -gt 0)) {
        $preInstalledModulePaths = Get-ChildItem -Path '/usr/share/az_*' -Directory
        $maximumVersionPath = '/usr/share/az_{0}' -f (($preInstalledModulePaths | ForEach-Object { ($_ -split 'az_')[1] }) | ForEach-Object { [version]$_ } | Measure-Object -Maximum ).Maximum
        Write-Verbose "Found pre-installed modules in path [$maximumVersionPath]. Adding it PSModulePath environment variable." -Verbose

        if ($IsWindows) {
            # Set step module path (process)
            $env:PSModulePath += ";$maximumVersionPath"
            # Set job module path (machine)
            [Environment]::SetEnvironmentVariable('PSModulePath', ('{0};{1}' -f ([Environment]::GetEnvironmentVariable('PSModulePath', 'Machine')), $maximumVersionPath), 'Machine')
            # Set PS-Profile (for non-ps tasks)
            Add-Content -Path $profile -Value "`$env:PSModulePath += `";$maximumVersionPath`""
        } else {
            # Set step module path (process)
            $env:PSModulePath += ":$maximumVersionPath"
            # Set job module path (machine)
            [Environment]::SetEnvironmentVariable('PSModulePath', ('{0}:{1}' -f ([Environment]::GetEnvironmentVariable('PSModulePath', 'Machine')), $maximumVersionPath), 'Machine')
            # Set PS-Profile (for non-ps tasks)
            Add-Content -Path $profile -Value "`$env:PSModulePath += `":$maximumVersionPath`""
        }
    }

    # Load already installed modules
    $installedModules = Get-Module -ListAvailable

    Write-Verbose ('Install-CustomModule start') -Verbose
    $count = 1
    Foreach ($Module in $PSModules) {
        Write-Verbose ('=====================') -Verbose
        Write-Verbose ('HANDLING MODULE [{0}/{1}] [{2}] ' -f $count, $PSModules.Count, $Module.Name) -Verbose
        Write-Verbose ('=====================') -Verbose
        # Installing New Modules and Removing Old
        $null = Install-CustomModule -Module $Module -InstalledModule $installedModules
        $count++
    }

    Write-Verbose ('Install-CustomModule end') -Verbose
}
