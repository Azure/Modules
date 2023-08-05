﻿<#
.SYNOPSIS
Remove a string to its core - i.e. the part the neither indicates plural nor singular.

.DESCRIPTION
Remove a string to its core - i.e. the part the neither indicates plural nor singular.

.PARAMETER StringToReduce
Mandatory. The string to reduce.

.EXAMPLE
Get-ReducedWordString -StringToReduce 'virtualMachines'

Returns 'virtualMachine'.

.EXAMPLE
Get-ReducedWordString -StringToReduce 'factories'

Returns 'factor'.
#>
function Get-ReducedWordString {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $StringToReduce
    )

    if ($StringToReduce -match '(.+?)(y|ii|ies|es|s)$') {
        return $Matches[1]
    }

    return $StringToReduce
}

<#
.SYNOPSIS
Try to find the actual provider namespace and resource type for a given resource identifier.

.DESCRIPTION
Try to find the actual provider namespace and resource type for a given resource identifier.
For example, for 'virtual-machine-images/image-template' it we want to find 'Microsoft.VirtualMachineImages/imageTemplates'.

.PARAMETER ResourceIdentifier
Mandatory. The resource identifier to search for.

.PARAMETER SpecsFilePath
Optional. The path to the specs file that contains all available provider namespaces & resource types. Defaults to 'utilities/src/apiSpecsList.json'.

.EXAMPLE
Get-SpecsAlignedResourceName -ResourceIdentifier 'virtual-machine-images/image-template'.

Returns 'Microsoft.VirtualMachineImages/imageTemplates'.
#>
function Get-SpecsAlignedResourceName {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $ResourceIdentifier,

        [Parameter(Mandatory = $false)]
        [string] $SpecsFilePath = (Join-Path (Split-Path (Split-Path $PSScriptRoot)) 'src' 'apiSpecsList.json')
    )

    $specs = ConvertFrom-Json (Get-Content $specsFilePath -Raw) -AsHashtable

    $reducedResourceIdentifier = $ResourceIdentifier -replace '-'

    $rawProviderNamespace, $rawResourceType = $reducedResourceIdentifier -Split '[\/|\\]', 2

    $foundProviderNamespaceMatches = ($specs.Keys | Sort-Object) | Where-Object { $_ -like "Microsoft.$rawProviderNamespace*" }

    if (-not $foundProviderNamespaceMatches) {
        $providerNamespace = "Microsoft.$rawProviderNamespace"
        Write-Warning "Failed to identify provider namespace [$rawProviderNamespace]. Falling back to [$providerNamespace]."
    } else {
        $providerNamespace = ($foundProviderNamespaceMatches.Count -eq 1) ? $foundProviderNamespaceMatches : $foundProviderNamespaceMatches[0]
    }

    $innerResourceTypes = $specs[$providerNamespace].Keys | Sort-Object
    $rawResourceTypeReduced = Get-ReducedWordString -StringToReduce $rawResourceType
    $foundResourceTypeMatches = $innerResourceTypes | Where-Object { $_ -like "$rawResourceTypeReduced*" }

    if (-not $foundResourceTypeMatches) {
        $resourceType = $reducedResourceIdentifier.Split('/')[0]
        Write-Warning "Failed to identify resource type [$rawResourceType] in provider namespace [$providerNamespace]. Fallback to [$resourceType]."
    } elseif ($foundResourceTypeMatches.Count -eq 1) {
        $resourceType = $foundResourceTypeMatches
    } else {
        # if more than one specs resource type matches the input resource type core string, get all specs core strings and check exact match
        # this is to avoid that e.g. web/connection fall to Microsoft.Web/connectionGateways instead of Microsoft.Web/connections
        foreach ($foundResourceTypeMatch in $foundResourceTypeMatches) {
            $foundResourceTypeMatchReduced = Get-ReducedWordString -StringToReduce $foundResourceTypeMatch
            if ($rawResourceTypeReduced -eq $foundResourceTypeMatchReduced) {
                $resourceType = $foundResourceTypeMatch
                break
            }
        }

        if (-not $resourceType) {
            $resourceType = $foundResourceTypeMatches[0]
            Write-Warning "Fallback to first ResourceType in the match list [$resourceType]."
        }
    }

    return "$providerNamespace/$resourceType"
}