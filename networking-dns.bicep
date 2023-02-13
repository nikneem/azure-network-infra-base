/*
This bicep file will create a new resource group end deploy a DNS Private Resolver
in that resource group. The DNS Private Resolver allows for resolving host names
in locations that could otherwise not resolve those names. For this network,
the DNS Private resolver is used to resolve hostnames on the internal VNet from
a point to site VPN connection.
*/

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

@description('This is the name of the resource group where the VNet lives. The VNet should already exist before running this template')
param vnetResourceGroup string
@description('This is the name of the VNet resoruce. The VNet should already exist before running this template')
param vnetName string
@description('This is the name of the subnet that the primary DNS Resolver inbound endpoint will live in')
param primarySubnetName string
@description('This is the name of the subnet that the secondary DNS Resolver inbound endpoint will live in')
param secondarySubnetName string
@description('This is the static IP address that the primary DNS resolver inbound endpoint must have')
param primaryStaticIpAddress string
@description('This is the static IP address that the secondary DNS resolver inbound endpoint must have')
param secondaryStaticIpAddress string

var dnsResourceName = toLower('${costCenter}-dns-${environmentName}-${locationAbbreviation}')

resource dnsResourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: dnsResourceName
  location: location
  tags: {
    costCenter: costCenter
  }
}

module dnsResolver 'networking-dns-resources.bicep' = {
  name: 'dnsResolverModule'
  scope: dnsResourceGroup
  params: {
    defaultResourceName: dnsResourceName
    location: location
    vnetName: vnetName
    vnetResourceGroup: vnetResourceGroup
    primarySubnetName: primarySubnetName
    primaryStaticIpAddress: primaryStaticIpAddress
    secondarySubnetName: secondarySubnetName
    secondaryStaticIpAddress: secondaryStaticIpAddress
  }
}
