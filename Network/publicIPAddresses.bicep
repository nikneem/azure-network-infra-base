@description('The name of the public IP address resource')
param resourceName string

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

@description('This is the label of the public IP address, this is often used for DNS Servers to CNAME to this label')
param label string

param location string = resourceGroup().location

resource ipAddress 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: resourceName
  location: location
  tags: {
    costCenter: costCenter
  }
  properties: {
    dnsSettings: {
      domainNameLabel: label
    }
  }
}

output publicIpAddress string = ipAddress.properties.ipAddress
