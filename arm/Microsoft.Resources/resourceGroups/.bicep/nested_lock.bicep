@description('Optional. The name of the lock.')
param name string = '${level}-lock'

@allowed([
  'CanNotDelete'
  'ReadOnly'
])
@description('Optional. Set lock level.')
param level string

@description('Optional. The decription attached to the lock.')
param notes string = level == 'CanNotDelete' ? 'Cannot delete resource or child resources.' : 'Cannot modify the resource or child resources.'

resource lock 'Microsoft.Authorization/locks@2017-04-01' = {
  name: name
  properties: {
    level: level
    notes: notes
  }
}

@description('The resource ID of the lock.')
output resourceId string = lock.id

@description('The name of the lock.')
output name string = lock.name
