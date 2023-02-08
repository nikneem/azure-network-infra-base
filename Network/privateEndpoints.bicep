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

@description('The name of your virtual network')
param vnetName string
@description('The name of the resource group that your virtual network lives in')
param vnetResourceGroup string
@description('The name of the subnet that your private endpoint must be created in')
param subnetName string
@description('The name of the private DNS zone that must contain an A entry to your resource (leave empty if to create no registration)')
param privateDnsZone string = ''
@description('ID of the resource that the private endpoint must link to')
param targetResourceId string
@description('Name of the private endpoint to be created')
param resourceName string

param location string = resourceGroup().location

@allowed([
  'configurationStores'
  'vault'
])
param groupId string

resource VNet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: vnetName
  scope: resourceGroup(vnetResourceGroup)

  resource Subnet 'subnets' existing = {
    name: subnetName
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2022-07-01' = {
  name: resourceName
  location: location
  tags: {
    costCenter: costCenter
  }
  properties: {
    subnet: {
      id: VNet::Subnet.id
    }
    customNetworkInterfaceName: '${resourceName}-nic'
    privateLinkServiceConnections: [
      {
        name: resourceName
        properties: {
          privateLinkServiceId: targetResourceId
          groupIds: [
            groupId
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Automatically Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
  }
}

resource dnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = if (privateDnsZone != '') {
  name: privateDnsZone
  scope: resourceGroup(vnetResourceGroup)
}

resource symbolicname 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-07-01' = if (privateDnsZone != '') {
  name: 'default'
  parent: privateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-azconfig-io'
        properties: {
          privateDnsZoneId: dnsZone.id
        }
      }
    ]
  }
}
