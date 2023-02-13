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

param location string = resourceGroup().location
param defaultResourceName string

param privateDnsZones array
var primaryInboundDnsResolverEndpointIpAddress = '10.250.0.4' // First available IP Address in DnsPrimaryInboundSubnet
var secondaryInboundDnsResolverEndpointIpAddress = '10.250.1.4' // First available IP Address in DnsSecondaryInboundSubnet
var primaryInboundDnsResolverSubnetName = 'DnsPrimaryInboundSubnet' // First available IP Address in DnsPrimaryInboundSubnet
var secondaryInboundDnsResolverSubnetName = 'DnsSecondaryInboundSubnet' // First available IP Address in DnsPrimaryInboundSubnet

var defaultSubnets = [
  {
    name: 'IntegrationConfigSubnet'
    properties: {
      addressPrefix: '10.0.0.0/24'
      delegations: []
      serviceEndpoints: []
    }
  }
  {
    name: 'IntegrationMessagingSubnet'
    properties: {
      addressPrefix: '10.0.1.0/24'
      delegations: []
      serviceEndpoints: []
    }
  }
  {
    name: 'IntegrationEventsSubnet'
    properties: {
      addressPrefix: '10.0.2.0/24'
      delegations: []
      serviceEndpoints: []
    }
  }
  {
    name: 'IntegrationCacheSubnet'
    properties: {
      addressPrefix: '10.0.3.0/24'
      delegations: []
      serviceEndpoints: []
    }
  }
  {
    name: 'IntegrationLogSubnet'
    properties: {
      addressPrefix: '10.0.4.0/24'
      delegations: []
      serviceEndpoints: []
    }
  }
  {
    name: 'AppGatewaySubnet'
    properties: {
      addressPrefix: '10.0.250.0/24'
      delegations: []
      serviceEndpoints: []
    }
  }
  {
    name: 'ApimSubnet'
    properties: {
      addressPrefix: '10.0.251.0/24'
      delegations: []
      serviceEndpoints: []
    }
  }
  {
    name: 'IdentityServiceSubnet'
    properties: {
      addressPrefix: '10.1.0.0/23'
      delegations: []
      serviceEndpoints: []
    }
  }
  {
    name: 'IdentityConfigDataSubnet'
    properties: {
      addressPrefix: '10.1.2.0/24'
      delegations: []
      serviceEndpoints: []
    }
  }
  {
    name: 'IdentityOperationalDataSubnet'
    properties: {
      addressPrefix: '10.1.3.0/24'
      delegations: []
      serviceEndpoints: []
    }
  }
  {
    name: primaryInboundDnsResolverSubnetName
    properties: {
      addressPrefix: '10.250.0.0/24'
      delegations: [
        {
          name: 'delegation'
          properties: {
            serviceName: 'Microsoft.Network/dnsResolvers'
          }
        }
      ]
      serviceEndpoints: []
    }
  }
  {
    name: secondaryInboundDnsResolverSubnetName
    properties: {
      addressPrefix: '10.250.1.0/24'
      delegations: [
        {
          name: 'delegation'
          properties: {
            serviceName: 'Microsoft.Network/dnsResolvers'
          }
        }
      ]
      serviceEndpoints: []
    }
  }
  {
    name: 'GatewaySubnet'
    properties: {
      addressPrefix: '10.255.255.0/24'
      delegations: []
      serviceEndpoints: []
    }
  }
]

var developmentSubnets = []

var subnets = environmentName == 'dev' ? union(defaultSubnets, developmentSubnets) : defaultSubnets

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: '${defaultResourceName}-vnet'
  location: location
  tags: {
    costCenter: costCenter
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/8'
      ]
    }
    subnets: subnets
    dhcpOptions: {
      dnsServers: [
        primaryInboundDnsResolverEndpointIpAddress
        secondaryInboundDnsResolverEndpointIpAddress
      ]
    }
  }
}

resource vpnGatewayPublicIp 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: '${defaultResourceName}-vpn-pip'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2022-07-01' = {
  name: '${defaultResourceName}-vpn'
  location: location
  properties: {
    enablePrivateIpAddress: false
    enableBgpRouteTranslationForNat: false
    sku: {
      name: 'VpnGw2AZ'
      tier: 'VpnGw2AZ'
    }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    activeActive: false
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: vpnGatewayPublicIp.id
          }
          subnet: {
            id: '${virtualNetwork.id}/subnets/GatewaySubnet'
          }
        }
      }
    ]
    bgpSettings: {
      asn: 0
      peerWeight: 0
    }
    vpnClientConfiguration: {
      aadAudience: '41b23e61-6c1e-4545-b367-cd054e0ed4b4'
      aadTenant: '${environment().authentication.loginEndpoint}${subscription().tenantId}'
      aadIssuer: 'https://sts.windows.net/${subscription().tenantId}/'
      vpnAuthenticationTypes: [
        'AAD'
      ]
      vpnClientAddressPool: {
        addressPrefixes: [
          '11.0.0.0/20'
        ]
      }
      vpnClientProtocols: [
        'OpenVPN'
      ]
    }
  }
}

module dnsZoneModule 'Network/privateDnsZones.bicep' = [for dnsZone in privateDnsZones: {
  name: 'PrivateDnsZone-${dnsZone}'
  params: {
    dnsZoneName: dnsZone
    virtualNetworkName: virtualNetwork.name
  }
}]

output resourceId string = virtualNetwork.id
output vnetName string = virtualNetwork.name

output primaryInboundDnsResolverEndpointIpAddress string = primaryInboundDnsResolverEndpointIpAddress
output secondaryInboundDnsResolverEndpointIpAddress string = secondaryInboundDnsResolverEndpointIpAddress
output primaryInboundDnsResolverSubnetName string = primaryInboundDnsResolverSubnetName
output secondaryInboundDnsResolverSubnetName string = secondaryInboundDnsResolverSubnetName
