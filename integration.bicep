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

module appConfigurationModule 'integration-appconfig.bicep' = {
  name: 'appConfigurationModule'
  params: {
    costCenter: costCenter
    defaultResourceName: defaultResourceName
    location: location
    vnetName: vnetName
    vnetResourceGroup: vnetResourceGroup
  }
}
module keyVaultModule 'integration-keyvault.bicep' = {
  name: 'keyVaultModule'
  params: {
    costCenter: costCenter
    defaultResourceName: defaultResourceName
    location: location
    vnetName: vnetName
    vnetResourceGroup: vnetResourceGroup
  }
}
