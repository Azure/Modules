# Sql Servers EncryptionProtector `[Microsoft.Sql/servers/encryptionProtector]`

This module deploys an Sql Servers Encryption Protector.

## Navigation

- [Resource Types](#Resource-Types)
- [Parameters](#Parameters)
- [Outputs](#Outputs)
- [Cross-referenced modules](#Cross-referenced-modules)

## Resource Types

| Resource Type | API Version |
| :-- | :-- |
| `Microsoft.Sql/servers/encryptionProtector` | [2021-11-01](https://learn.microsoft.com/en-us/azure/templates/Microsoft.Sql/2021-11-01/servers/encryptionProtector) |

## Parameters

**Required parameters**

| Parameter Name | Type | Description |
| :-- | :-- | :-- |
| `serverKeyName` | string | The name of the server key. |

**Conditional parameters**

| Parameter Name | Type | Description |
| :-- | :-- | :-- |
| `sqlServerName` | string | The name of the sql server. |

**Optional parameters**

| Parameter Name | Type | Default Value | Allowed Values | Description |
| :-- | :-- | :-- | :-- | :-- |
| `autoRotationEnabled` | bool | `False` |  | Key auto rotation opt-in. |
| `enableDefaultTelemetry` | bool | `True` |  | Enable telemetry via a Globally Unique Identifier (GUID). |
| `serverKeyType` | string | `'ServiceManaged'` | `[AzureKeyVault, ServiceManaged]` | The encryption protector type like "ServiceManaged", "AzureKeyVault". |


## Outputs

| Output Name | Type | Description |
| :-- | :-- | :-- |
| `name` | string | The name of the deployed encryption protector. |
| `resourceGroupName` | string | The resource group of the deployed encryption protector. |
| `resourceId` | string | The resource ID of the encryption protector. |

## Cross-referenced modules

_None_
