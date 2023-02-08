@description('This is the name of the team that is the owner of this service')
@allowed([
  'gd'
  'ds'
  'es'
  'iot'
  'mp'
  'bi'
])
@maxLength(3)
param costCenter string

param vnetName string
param vnetResourceGroup string

param location string = resourceGroup().location
param defaultResourceName string

resource appConfiguration 'Microsoft.AppConfiguration/configurationStores@2022-05-01' = {
  name: '${defaultResourceName}-cfg'
  location: location
  sku: {
    name: 'standard'
  }
  tags: {
    costCenter: costCenter
  }
  properties: {
    publicNetworkAccess: 'Disabled'
    softDeleteRetentionInDays: 5
  }
}

resource appConfigurationValue 'Microsoft.AppConfiguration/configurationStores/keyValues@2022-05-01' = {
  name: 'ConfigurationValue'
  parent: appConfiguration
  properties: {
    contentType: 'text/plain'
    value: 'Configured Value'
  }
}

module appConfigurationPrivateEndpoint 'Network/privateEndpoints.bicep' = {
  name: 'appConfigurationPrivateEndpointModule'
  params: {
    costCenter: costCenter
    targetResourceId: appConfiguration.id
    resourceName: '${defaultResourceName}-cfg-pe'
    subnetName: 'IntegrationConfig'
    location: location
    vnetName: vnetName
    vnetResourceGroup: vnetResourceGroup
    privateDnsZone: 'privatelink.azconfig.io'
    groupId: 'configurationStores'
  }
}
