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
param location string = deployment().location
param privateDnsZones array

module virtualNetworkModule 'networking-vnet.bicep' = {
  name: 'virtualNetworkModule'
  params: {
    location: location
    costCenter: costCenter
    environmentName: environmentName
    locationAbbreviation: locationAbbreviation
    privateDnsZones: privateDnsZones
  }
}

module dnsPrivateResolverModule 'networking-dns.bicep' = {
  name: 'dnsPrivateResolverModule'
  params: {
    location: location
    costCenter: costCenter
    environmentName: environmentName
    locationAbbreviation: locationAbbreviation
    vnetResourceGroup: virtualNetworkModule.outputs.vnetResourceGroupName
    vnetName: virtualNetworkModule.outputs.vnetName
    primarySubnetName: virtualNetworkModule.outputs.primaryInboundDnsResolverSubnetName
    primaryStaticIpAddress: virtualNetworkModule.outputs.primaryInboundDnsResolverEndpointIpAddress
    secondarySubnetName: virtualNetworkModule.outputs.secondaryInboundDnsResolverSubnetName
    secondaryStaticIpAddress: virtualNetworkModule.outputs.secondaryInboundDnsResolverEndpointIpAddress
  }
}

module integrationModule 'integration.bicep' = {
  name: 'integrationModule'
  params: {
    location: location
    costCenter: costCenter
    environmentName: environmentName
    locationAbbreviation: locationAbbreviation
    vnetResourceGroup: virtualNetworkModule.outputs.vnetResourceGroupName
    vnetName: virtualNetworkModule.outputs.vnetName
  }
}
