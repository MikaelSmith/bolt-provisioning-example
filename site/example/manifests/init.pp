class example (
  String $subscription_id = azure_subscription_id(),
  String $project_name    = 'azblogpost',
  String $location        = 'westus2',
  String $admin_user      = 'testAdmin',
  String $admin_password,
) {

  $rg              = "${project_name}-rg-name"
  $storage_account = "${project_name}saccount"
  $nsg             = "${project_name}-nsg"
  $vnet            = "${project_name}-vnet"
  $subnet          = "${project_name}-subnet"

  # Base names for the vm's
  $nic_project_name = "${project_name}-nic"
  $vm_project_name  = "${project_name}vm"

  $address_prefix = '10.0.0.0/24'

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

    azure_network_interface { "${nic_project_name}-${idx}":
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
          name => "${project_name}-nic-ipconfig",
          }]
      }
    }

    # Windows names can't use dash
    azure_virtual_machine { "${vm_project_name}${idx}":
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
            name         => "${vm_project_name}${idx}",
            createOption => 'FromImage',
            caching      => 'None',
            vhd          => {
              uri => "https://${$storage_account}.blob.core.windows.net/${vm_project_name}${idx}-container/${vm_project_name}${idx}.vhd"
            },
          },
          dataDisks      => []
        },
        osProfile              => {
          computerName         => "${vm_project_name}${idx}",
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
            id      => "/subscriptions/${subscription_id}/resourceGroups/${rg}/providers/Microsoft.Network/networkInterfaces/${nic_project_name}-${idx}",
            primary => true
            }]
        },
      },
      type                => 'Microsoft.Compute/virtualMachines',
    }
  }
}
