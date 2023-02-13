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

@description('This is the name of the resource group where the VNet lives. The VNet should already exist before running this template')
param vnetResourceGroup string
@description('This is the name of the VNet resoruce. The VNet should already exist before running this template')
param vnetName string

param location string

var integrationResourceName = toLower('${costCenter}-int-${environmentName}-${locationAbbreviation}')

resource integrationResourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: integrationResourceName
  location: location
  tags: {
    costCenter: costCenter
  }
}

module integrationResources 'integration-configuration.bicep' = {
  name: 'integrationResourcesModule'
  scope: integrationResourceGroup
  params: {
    location: location
    costCenter: costCenter
    defaultResourceName: integrationResourceGroup.name
    vnetResourceGroup: vnetResourceGroup
    vnetName: vnetName
  }
}

// module integration 'integration.bicep' = {
//   name: 'integrationModule'
//   scope: integrationResourceGroup
//   params: {
//     costCenter: costCenter
//     location: location
//     defaultResourceName: integrationResourceName
//     vnetName: virtualNetwork.outputs.vnetName
//     vnetResourceGroup: networkingResourceGroup.name
//   }
// }

// module appConfigurationModule 'integration-appconfig.bicep' = {
//   name: 'appConfigurationModule'
//   params: {
//     costCenter: costCenter
//     defaultResourceName: defaultResourceName
//     location: location
//     vnetName: vnetName
//     vnetResourceGroup: vnetResourceGroup
//   }
// }
// module keyVaultModule 'integration-keyvault.bicep' = {
//   name: 'keyVaultModule'
//   params: {
//     costCenter: costCenter
//     defaultResourceName: defaultResourceName
//     location: location
//     vnetName: vnetName
//     vnetResourceGroup: vnetResourceGroup
//   }
// }
