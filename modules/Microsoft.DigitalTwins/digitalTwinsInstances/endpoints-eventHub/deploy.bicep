@description('Optional. The name of the Digital Twin Endpoint.')
param name string = 'EventHubEndpoint'

@description('Conditional. The name of the parent Digital Twin Instance resource. Required if the template is used in a standalone deployment.')
param digitalTwinInstanceName string

@description('Optional. Specifies the authentication type being used for connecting to the endpoint. If \'KeyBased\' is selected, a connection string must be specified (at least the primary connection string). If \'IdentityBased\' is selected, the endpointUri and entityPath properties must be specified.')
param authenticationType string = 'KeyBased'

@description('Optional. Dead letter storage secret for key-based authentication. Will be obfuscated during read.')
@secure()
param deadLetterSecret string = ''

@description('Optional. Dead letter storage URL for identity-based authentication.')
param deadLetterUri string = ''

@description('Optional. PrimaryConnectionString of the endpoint for key-based authentication. Will be obfuscated during read.')
@secure()
param connectionStringPrimaryKey string = ''

@description('Optional. SecondaryConnectionString of the endpoint for key-based authentication. Will be obfuscated during read.')
@secure()
param connectionStringSecondaryKey string = ''

@description('Optional. The EventHub name in the EventHub namespace for identity-based authentication.')
param entityPath string = ''

@description('Optional. The URL of the EventHub namespace for identity-based authentication. It must include the protocol \'sb://\'.')
param endpointUri string = ''

resource digitalTwinsInstance 'Microsoft.DigitalTwins/digitalTwinsInstances@2022-05-31' existing = {
  name: digitalTwinInstanceName
}

resource endpoint 'Microsoft.DigitalTwins/digitalTwinsInstances/endpoints@2022-10-31' = {
  name: name
  parent: digitalTwinsInstance
  properties: {
    endpointType: 'EventHub'
    authenticationType: authenticationType
    connectionStringPrimaryKey: connectionStringPrimaryKey
    connectionStringSecondaryKey: connectionStringSecondaryKey
    deadLetterSecret: deadLetterSecret
    deadLetterUri: deadLetterUri
    endpointUri: endpointUri
    entityPath: entityPath
  }
}

@description('The resource ID of the Endpoint.')
output resourceId string = endpoint.id

@description('The name of the resource group the resource was created in.')
output resourceGroupName string = resourceGroup().name

@description('The name of the Endpoint.')
output name string = endpoint.name
