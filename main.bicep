targetScope = 'subscription'

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

// @description('This is a descriptive name of your service. The name should be shortened to a max of 5 characters')
// @maxLength(5)
// param systemName string

@description('This is the name of the environment that you target. Allowed values are dev, tst, acc and prd')
@allowed([
  'dev'
  'tst'
  'acc'
  'prd'
])
@maxLength(3)
param environmentName string

@description('This is an abbreviation of the Azure region your services is deployed to. Allowed values are weu and neu for west- and north Europe')
@allowed([
  'weu'
  'neu'
])
@maxLength(3)
param locationAbbreviation string

param location string = deployment().location

param privateDnsZones array

var networkingResourceName = toLower('${costCenter}-net-${environmentName}-${locationAbbreviation}')

resource networkingResourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: networkingResourceName
  location: location
  tags: {
    costCenter: costCenter
  }
}

module virtualNetwork 'networking.bicep' = {
  name: 'virtualNetworkModule'
  scope: networkingResourceGroup
  params: {
    costCenter: costCenter
    environmentName: environmentName
    location: location
    defaultResourceName: networkingResourceName
    privateDnsZones: privateDnsZones
  }
}

var integrationResourceName = toLower('${costCenter}-int-${environmentName}-${locationAbbreviation}')

resource integrationResourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: integrationResourceName
  location: location
  tags: {
    costCenter: costCenter
  }
}

module integration 'integration.bicep' = {
  name: 'integrationModule'
  scope: integrationResourceGroup
  params: {
    costCenter: costCenter
    location: location
    defaultResourceName: integrationResourceName
    vnetName: virtualNetwork.outputs.vnetName
    vnetResourceGroup: networkingResourceGroup.name
  }
}
