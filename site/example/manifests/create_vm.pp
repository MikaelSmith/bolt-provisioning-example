## Secrets
# azure_client_name=AzureBlogPost
# azure_client_secret=9az38271X

$base_name    = 'azblogpost'
$rg               = "${base_name}-rg-name"
$storage_account  = "${base_name}saccount"
$nsg              = "${base_name}-nsg"
$vnet             = "${base_name}-vnet"
$subnet           = "${base_name}-subnet"
$location         = 'westus2'
$subscription_id = 'f5d9ef40-7475-4330-be87-61297b2d14ed'

# Base names for the vm's
$nic_base_name    = "${base_name}-nic"
$vm_base_name     = "${base_name}vm"

$address_prefix = '10.0.0.0/24'

$admin_user = 'testAdmin'
$admin_password = 'p2n6P39jhncwMkU'

# Re-use basic azure resources for the VMs
azure_resource_group { $rg:
  ensure              => present,
  parameters          => {},
  location            => $location
}

azure_storage_account { $storage_account:
  ensure              => present,
  parameters          => {},
  resource_group_name => $rg,
  account_name        => $storage_account,
  location            => $location,
  sku                 => {
    name => 'Standard_LRS',
    tier => 'Standard',
  }
}

# Open WinRM
azure_network_security_group { $nsg :
  ensure                         => present,
  parameters                     => {},
  resource_group_name            => $rg,
  location                       => $location,
  properties                     => {
    securityRules                => [{
      name                       => 'AllowRemoteAdmin',
      properties                 => {
        access                   => 'Allow',
        destinationAddressPrefix => '*',
        destinationPortRange     => '5985',
        direction                => 'Inbound',
        priority                 => '100',
        protocol                 => '*',
        sourceAddressPrefix      => '*',
        sourcePortRange          => '*',
      }
      }]
  }
}

azure_virtual_network { $vnet:
  ensure               => present,
  parameters           => {},
  location             => $location,
  resource_group_name  => $rg,
  properties           => {
    addressSpace => {
      addressPrefixes => [$address_prefix]
    },
    dhcpOptions  => {
      dnsServers => ['8.8.8.8', '8.8.4.4']
    },
    subnets      => [{
      name       => $subnet,
      properties => {
        addressPrefix => $address_prefix
      }
      }]
  }
}

azure_subnet { $subnet:
  ensure               => present,
  subnet_parameters    => {},
  virtual_network_name => $vnet,
  resource_group_name  => $rg,
  properties           => {
    addressPrefix        => $address_prefix,
    networkSecurityGroup => {
      properties => {},
      id         => "/subscriptions/${subscription_id}/resourceGroups/${rg}/providers/Microsoft.Network/networkSecurityGroups/${nsg}"
    }
  }
}

# Create multiple NIC's and VM's
[1, 2].each |$idx| {

  azure_public_ip_address { "ipaddress-${idx}":
    ensure              => present,
    parameters          => {},
    resource_group_name => $rg,
    location            => $location,
  }

  azure_network_interface { "${nic_base_name}-${idx}":
    ensure                 => present,
    parameters             => {},
    resource_group_name    => $rg,
    location               => $location,
    properties             => {
      networkSecurityGroup => {
        properties => {},
        id         => "/subscriptions/${subscription_id}/resourceGroups/${rg}/providers/Microsoft.Network/networkSecurityGroups/${nsg}"
      },
      ipConfigurations     => [{
        properties                  => {
          privateIPAllocationMethod => 'Dynamic',
          publicIPAddress           => {
            id => "/subscriptions/${subscription_id}/resourceGroups/${rg}/providers/Microsoft.Network/publicIPAddresses/ipaddress-${idx}",
          },
          subnet                    => {
            id         => "/subscriptions/${subscription_id}/resourceGroups/${rg}/providers/Microsoft.Network/virtualNetworks/${vnet}/subnets/${subnet}",
            properties => {
              addressPrefix     => $address_prefix,
              provisioningState => 'Succeeded'
            },
            name       => $subnet
          },
        },
        name => "${base_name}-nic-ipconfig",
        }]
    }
  }

  # Windows names can't use dash
  azure_virtual_machine { "${vm_base_name}${idx}":
    ensure              => 'present',
    parameters          => {},
    location            => $location,
    resource_group_name => $rg,
    properties          => {
      hardwareProfile => {
        vmSize => 'Standard_D2_v3'
      },
      storageProfile  => {
        imageReference => {
          publisher => 'MicrosoftWindowsServer',
          offer     => 'WindowsServer',
          sku       => '2016-Datacenter-Server-Core',
          version   => 'latest'
        },
        osDisk         => {
          name         => "${vm_base_name}${idx}",
          createOption => 'FromImage',
          caching      => 'None',
          vhd          => {
            uri => "https://${$storage_account}.blob.core.windows.net/${vm_base_name}${idx}-container/${vm_base_name}${idx}.vhd"
          },
        },
        dataDisks      => []
      },
      osProfile              => {
        computerName         => "${vm_base_name}${idx}",
        adminUsername        => $admin_user,
        adminPassword        => $admin_password,
        windowsConfiguration => {
          winRM              => {
            listeners        => [{
              protocol       => 'http',
              }]
          }
        },
      },
      networkProfile  => {
        networkInterfaces => [{
          id      => "/subscriptions/${subscription_id}/resourceGroups/${rg}/providers/Microsoft.Network/networkInterfaces/${nic_base_name}-${idx}",
          primary => true
          }]
      },
    },
    type                => 'Microsoft.Compute/virtualMachines',
  }
}
