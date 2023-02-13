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

module appConfigurationPrivateEndpoint 'Network/privateEndpoints.bicep' = {
  name: 'appConfigurationPrivateEndpointModule'
  params: {
    costCenter: costCenter
    targetResourceId: appConfiguration.id
    resourceName: '${defaultResourceName}-cfg-pe'
    subnetName: 'IntegrationConfigSubnet'
    location: location
    vnetName: vnetName
    vnetResourceGroup: vnetResourceGroup
    privateDnsZone: 'privatelink.azconfig.io'
    groupId: 'configurationStores'
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: '${defaultResourceName}-kv'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    publicNetworkAccess: 'Disabled'
  }
}

module keyVaultPrivateEndpoint 'Network/privateEndpoints.bicep' = {
  name: 'keyVaultPrivateEndpointModule'
  params: {
    costCenter: costCenter
    targetResourceId: keyVault.id
    resourceName: '${defaultResourceName}-kv-pe'
    subnetName: 'IntegrationConfigSubnet'
    location: location
    vnetName: vnetName
    vnetResourceGroup: vnetResourceGroup
    privateDnsZone: 'privatelink.vaultcore.azure.net'
    groupId: 'vault'
  }
}
