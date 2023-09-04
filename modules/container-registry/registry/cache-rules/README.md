# Container Registries Cache `[Microsoft.ContainerRegistry/registries/cacheRules]`

Cache for Azure Container Registry (Preview) feature allows users to cache container images in a private container registry. Cache for ACR, is a preview feature available in Basic, Standard, and Premium service tiers. https://learn.microsoft.com/en-us/azure/container-registry/tutorial-registry-cache.

## Navigation

- [Resource Types](#Resource-Types)
- [Parameters](#Parameters)
- [Outputs](#Outputs)
- [Cross-referenced modules](#Cross-referenced-modules)

## Resource Types

| Resource Type | API Version |
| :-- | :-- |
| `Microsoft.ContainerRegistry/registries/cacheRules` | [2023-06-01-preview](https://learn.microsoft.com/en-us/azure/templates/Microsoft.ContainerRegistry/registries/cacheRules) |

## Parameters

**Required parameters**

| Parameter Name | Type | Description |
| :-- | :-- | :-- |
| `sourceRepository` | string | Source repository pulled from upstream. |

**Conditional parameters**

| Parameter Name | Type | Default Value | Description |
| :-- | :-- | :-- | :-- |
| `name` | string | `[replace(replace(parameters('sourceRepository'), '/', '-'), '.', '-')]` | The name of the cache rule. Will be dereived from the source repository name if not defined. |
| `registryName` | string |  | The name of the parent registry. Required if the template is used in a standalone deployment. |

**Optional parameters**

| Parameter Name | Type | Default Value | Description |
| :-- | :-- | :-- | :-- |
| `credentialSetResourceId` | string | `''` | The resource ID of the credential store which is associated with the cache rule. |
| `targetRepository` | string | `[parameters('sourceRepository')]` | Target repository specified in docker pull command. E.g.: docker pull myregistry.azurecr.io/{targetRepository}:{tag}. |


## Outputs

| Output Name | Type | Description |
| :-- | :-- | :-- |
| `name` | string | The Name of the Cache Rule. |
| `resourceGroupName` | string | The name of the Cache Rule. |
| `resourceId` | string | The resource ID of the Cache Rule. |

## Cross-referenced modules

_None_