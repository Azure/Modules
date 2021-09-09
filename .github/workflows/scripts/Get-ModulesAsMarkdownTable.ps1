#region Helper functions

<#
.SYNOPSIS
Get a properly formatted 'Deploy to Azure' button for the template in the given path

.DESCRIPTION
Get a properly formatted 'Deploy to Azure' button for the template in the given path
NOTE: This function requires that the Repo lives inside the 'Azure' organization

.PARAMETER path
Mandatory. The path to the module to generate the url for

.PARAMETER repositoryName
Mandatory. The name of the repository the content is included in.

.EXAMPLE
Get-DeployToAzureUrl -path 'C:\Modules\MyModule' -repositoryName 'Modules'

Generate an 'Deploy to Azure' button for module 'MyModule'
#>
function Get-DeployToAzureUrl {


    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $path,

        [Parameter(Mandatory)]
        [string] $repositoryName
    )

    if (-not (Test-Path -Path "$path\deploy.json")) {
        Write-Warning "ARM Template in path [$path\deploy.json] not found. Unable to generate 'Deploy to Azure' button."
        return ''
    }

    $baseUrl = "[![Deploy to Azure](/docs/media/deploytoazure.svg?sanitize=true)](<https://portal.azure.com/#create/Microsoft.Template/uri/"
    $templateUri = "https://raw.githubusercontent.com/Azure/{0}/main/{1}/deploy.json" -f $repositoryName, ($path -split "\\$repositoryName\\")[1]

    return ("{0}{1}>)" -f $baseUrl, ([System.Web.HttpUtility]::UrlEncode($templateUri)))
}

<#
.SYNOPSIS
Extract the resource name from the provided module path's readme

.DESCRIPTION
Extract the resource name from the provided module path's readme

.PARAMETER path
Mandatory. The path to the module to process

.EXAMPLE
Get-ResourceModuleName -path 'C:\KeyVault'

Get the resource name defined in the KeyVault-Module's readme. E.g. 'Key Vault'
#>
function Get-ResourceModuleName {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $path
    )

    if (-not (Test-Path "$path/readme.md")) {
        Write-Warning "No [readme.md] found in folder [$path]"
        return ""
    }

    $moduleReadMeContent = Get-Content -Path "$path/readme.md"
    $moduleName = $moduleReadMeContent[0].TrimStart('# ')

    if (-not [String]::IsNullOrEmpty($moduleName)) {
        return $moduleName
    }
    else {
        return ""
    }
}

<#
.SYNOPSIS
Get a string that indicates whether there are ARM/Bicep templates available in the given path

.DESCRIPTION
Get a string that indicates whether there are ARM/Bicep templates available in the given path.
The string represents markdown table columns.
Files must follow the naming schema 'deploy.json' & 'deploy.bicep'

.PARAMETER path
Mandatory. The path to check for templates

.EXAMPLE
Get-TypeColumnString -path 'C:\MyModule'

May return a string like ':heavy_check_mark: | :heavy_check_mark: |' if both ARM & bicep templates are available in the given module path
#>
function Get-TypeColumnString {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $path
    )

    $moduleFiles = Get-ChildItem -Path $path -File

    $outputString = ""

    if ($moduleFiles.Name -contains 'deploy.json') {
        # ARM exists
        $outputString += ":heavy_check_mark:/"
    }
    else {
        $outputString += " /"
    }

    if ($moduleFiles.Name -contains 'deploy.bicep') {
        # bicep exists
        $outputString += ":heavy_check_mark:"
    }
    else {
        $outputString += ""
    }

    return $outputString
}


<#
.SYNOPSIS
Get the number of nested module levels

.DESCRIPTION
Get the number of nested module levels. If the return value is greater than 0, the provided folder path contains at least one module in a lower level
A module is identified by folders that do not contain module-specific folders such as 'parameters'.
In other words, a module would contain a folder with e.g. a 'parameters' folder and would hence not count towards the hierarchy of parent folders.

.PARAMETER path
Mandatory. The path to search in.

.EXAMPLE
> (Get-RelevantDepth -path 'C:\dev\ApiManagement') -gt 0

Check if the path 'C:\dev\ApiManagement' contains any number of nested modules
#>
function Get-RelevantDepth {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $path
    )

    # Get only folders that contain no files (aka are parent folders)
    if (-not ($relevantSubfolders = (Get-Childitem $path -Directory -Recurse -Exclude @('.bicep', 'parameters')).fullName)) {
        return 0
    }
    $sanitizedPaths = $relevantSubfolders | ForEach-Object { $_.Replace($path, '') }

    $depths = $sanitizedPaths | ForEach-Object { ($_.Split('\') | Measure-Object).Count - 1 }

    return ($depths | Measure-Object -Maximum).Maximum
}

<#
.SYNOPSIS
Populate the given row with sub-modules in the given path

.DESCRIPTION
Populate the given row with sub-modules in the given path. Resources are concanted as a path.

.PARAMETER subPath
Mandatory. The path to process with respect to its contained modules

.PARAMETER concatedBase
Mandatory. The relative folder path from root down to the current level.

.PARAMETER row
Mandatory. The table row to populate/concat with additional modules

.PARAMETER provider
Mandatory. The current provider for this path

.PARAMETER columnsInOrder
Mandatory. The set of columns to add to the table in the order you expect them in the table.
Available are 'Name', 'Provider namespace', 'Resource Type', 'ARM / Bicep' and 'Deploy'

.EXAMPLE
> Get-ResolvedSubServiceRow -subPath 'C:\dev\Microsoft.ApiManagement\serviceResources' -concatedBase "Microsoft.ApiManagement\serviceResources" -row "| `Microsoft.ApiManagement` | <p>[service](Microsoft.ApiManagement\service)" -provider "Microsoft.ApiManagement"

Populate row "| `Microsoft.ApiManagement` | <p>[service](Microsoft.ApiManagement\service)" with additional modules found in path 'C:\dev\Microsoft.ApiManagement\serviceResources'
#>
function Get-ResolvedSubServiceRow {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $subPath,

        [Parameter(Mandatory)]
        [string] $concatedBase,

        [Parameter(Mandatory)]
        [System.Collections.ArrayList] $output,

        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [string] $provider,

        [Parameter(Mandatory)]
        [string[]] $columnsInOrder,

        [Parameter(Mandatory)]
        [ValidateSet("Name", "ProviderNamespace")]
        [string] $sortByColumn,

        [Parameter(Mandatory = $false)]
        [string] $repositoryName
    )

    $subFolders = Get-ChildItem -Path $subPath -Directory -Recurse -Exclude @('.bicep', 'parameters')

    foreach ($subfolder in $subFolders.FullName) {
        $subFolderName = (Split-Path $subfolder -Leaf)

        $relativePath = Join-Path $concatedBase $subFolderName
        $subName = $relativePath.Replace("$provider\", '').Replace('Resources\', '\')

        $row = @{}
        foreach ($column in $columnsInOrder) {
            switch ($column) {
                'Name' {
                    $row['Name'] = Get-ResourceModuleName -path $subfolder
                }
                'ProviderNamespace' {
                    # If we don't sort by provider, we have to add the provider to each row to ensure readability of each row
                    if ($sortByColumn -eq "Name") {
                        if ($provider -like "Microsoft.*") {
                            # Shorten Microsoft to save some space
                            $shortProvider = "MS.{0}" -f ($provider.TrimStart('Microsoft.'))
                            $row['ProviderNamespace'] += "``$shortProvider``"
                        }
                        else {
                            $row['ProviderNamespace'] += "``$provider``"
                        }
                    }
                    else {
                        $row['ProviderNamespace'] = ''
                    }
                }
                'ResourceType' {
                    $row['ResourceType'] += ('[{0}]({1})' -f $subName, $relativePath).Replace('\', '/')
                }
                'TemplateType' {
                    $row['TemplateType'] += Get-TypeColumnString -path $subfolder
                }
                'Deploy' {

                    if (-not $repositoryName) {
                        throw "If you want to generate a 'Deploy to Azure button' you must provide the 'repositoryName' parameter"
                    }
                    $row['Deploy'] += Get-DeployToAzureUrl -path $subfolder -repositoryName $repositoryName
                }
                Default {
                    Write-Warning "Column [$column] not existing. Available are: [ Name |Provider namespace | Resource Type | ARM / Bicep | Deploy ]"
                }
            }
        }
        $null = $output += $row
    }
    return $output
}
#endregion

<#
.SYNOPSIS
Generate a markdown table for all modules in the given path.

.DESCRIPTION
Generate a markdown table for all modules in the given path. Returns an array with one row for each service provider.
Folders should follow the structure:

Microsoft.Sql
├─ server [module]
└─ serverResources
    └─ databases [module]

Where sub-resources are part of a subfolder [<parentResource>Resources]

Results in a table like

    "| Name                           | Provider namespace | Resource Type                                                                   | ARM / Bicep |"
    "| ------------------------------ | ------------------ | ------------------------------------------------------------------------------- | ----------- |"
    "| SQL Managed Instances          | `Microsoft.Sql`    | [managedInstances](Microsoft.Sql/managedInstances)                              | :heavy_check_mark: / |
    "| SQL Managed Instances Database |                    | [managedInstances\databases](Microsoft.Sql\managedInstancesResources\databases) | :heavy_check_mark: / :heavy_check_mark: |

.PARAMETER path
Mandatory. The path to resolve

.PARAMETER columnsInOrder
Optional. The set of columns to add to the table in the order you expect them in the table.
Available are 'Name', 'ProviderNamespace', 'ResourceType', 'TemplateType' and 'Deploy'

.EXAMPLE
Get-ModulesAsMarkdownTable -path 'C:\dev\Modules'

Generate a markdown table for all modules in path 'C:\dev\Modules' with all default columns

.EXAMPLE
Get-ModulesAsMarkdownTable -path 'C:\dev\Modules' -columnsInOrder @('Resource Type', 'Name')

Generate a markdown table for all modules in path 'C:\dev\Modules' with only the 'Resource Type' & 'Name' columns
#>
function Get-ModulesAsMarkdownTable {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $path,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Name', 'ProviderNamespace', 'ResourceType', 'ARM / Bicep', 'Deploy')]
        [string[]] $columnsInOrder = @('Name', 'ProviderNamespace', 'ResourceType', 'TemplateType', 'Deploy'),

        [Parameter(Mandatory = $false)]
        [ValidateSet("Name", "ProviderNamespace")]
        [string] $sortByColumn = 'ProviderNamespace',

        [Parameter(Mandatory = $false)]
        [string] $repositoryName
    )

    # Header
    # ------
    $headerRow = "|"
    foreach ($column in $columnsInOrder) {
        switch ($column) {
            'Name' { $headerRow += ' Name |' }
            'ProviderNamespace' { $headerRow += ' Provider namespace |' }
            'ResourceType' { $headerRow += ' Resource Type |' }
            'TemplateType' { $headerRow += ' ARM / Bicep |' }
            'Deploy' { $headerRow += ' Deploy |' }
            Default {
                Write-Warning "Column [$column] not existing. Available are: [ Name |Provider namespace | Resource Type | ARM / Bicep | Deploy ]"
            }
        }
    }

    $headerSubRow = "|"
    for ($index = 0; $index -lt $columnsInOrder.Count; $index++) {
        $headerSubRow += ' - |'
    }

    # Content
    # -------
    $output = [System.Collections.ArrayList]@()
    if ($topLevelFolders = Get-ChildItem -Path $path -Depth 1 -Filter "Microsoft.*") {
        $topLevelFolders = $topLevelFolders.FullName | Sort-Object
    }

    $previousProvider = ''
    foreach ($topLevelFolder in $topLevelFolders) {
        $provider = Split-Path $topLevelFolder -Leaf

        $subFolders = Get-ChildItem -Path $topLevelFolder -Directory -Recurse -Exclude @('.bicep', 'parameters') -Depth 0

        foreach ($subfolder in $subFolders.FullName) {
            $subFolderName = (Split-Path $subfolder -Leaf)
            $concatedBase = $subfolder.Replace((Split-Path $topLevelFolder -Parent), '').Substring(1)

            if ((Get-RelevantDepth -path $subfolder) -gt 0) {
                $recursiveSubServiceInputObject = @{
                    subPath        = $subfolder
                    concatedBase   = $concatedBase
                    output         = $output
                    provider       = $provider
                    columnsInOrder = $columnsInOrder
                    repositoryName = $repositoryName
                    sortByColumn   = $sortByColumn
                }
                $output = Get-ResolvedSubServiceRow @recursiveSubServiceInputObject
            }
            else {

                $row = @{}

                foreach ($column in $columnsInOrder) {
                    switch ($column) {
                        'Name' {
                            $row['Name'] = Get-ResourceModuleName -path $subfolder
                        }
                        'ProviderNamespace' {
                            if ($previousProvider -eq $provider -and $sortByColumn -ne 'Name') {
                                $row['ProviderNamespace'] += ""
                            }
                            else {
                                if ($provider -like "Microsoft.*") {
                                    # Shorten Microsoft to save some space
                                    $shortProvider = "MS.{0}" -f ($provider.TrimStart('Microsoft.'))
                                    $row['ProviderNamespace'] += "``$shortProvider``"
                                }
                                else {
                                    $row['ProviderNamespace'] += "``$provider``"
                                }
                                $previousProvider = $provider
                            }
                        }
                        'ResourceType' {
                            $row['ResourceType'] += ('[{0}]({1})' -f $subFolderName, $concatedBase).Replace('\', '/')
                        }
                        'TemplateType' {
                            $row['TemplateType'] += Get-TypeColumnString -path $subfolder
                        }
                        'Deploy' {
                            if (-not $repositoryName) {
                                throw "If you want to generate a 'Deploy to Azure button' you must provide the 'repositoryName' parameter"
                            }
                            $row['Deploy'] += Get-DeployToAzureUrl -path $subfolder -repositoryName $repositoryName
                        }
                        Default {
                            Write-Warning "Column [$column] not existing. Available are: [ Name |Provider namespace | Resource Type | ARM / Bicep | Deploy ]"
                        }
                    }
                }

                $null = $output += $row
            }
        }
    }

    # Validate order
    if ($sortByColumn -eq 'Name') {
        $output = $output | Sort-Object -Property 'Name'
    }

    # Build result set
    $table = [System.Collections.ArrayList]@(
        $headerRow,
        $headerSubRow
    )
    foreach ($rowColumns in $output) {
        $rowString = "|"
        foreach ($column in $columnsInOrder) {
            $rowString += ' {0} |' -f $rowColumns[$column]
        }
        $table += $rowString
    }

    return $table
}