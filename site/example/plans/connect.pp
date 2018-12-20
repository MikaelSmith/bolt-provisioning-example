plan example::connect(TargetSpec $proxy = 'local://', String $admin_user, String $admin_password) {
  # TODO: get from apply somehow
  $vm_names = ['azblogpostvm1', 'azblogpostvm2']

  $vms = example::type_instances($proxy, 'azure_virtual_machine', $vm_names)
  $nic_names = $vms.map |$vm| { $vm['parameters']['properties']['networkProfile']['networkInterfaces'][0]['id'].split('/')[-1] }

  $nics = example::type_instances($proxy, 'azure_network_interface', $nic_names)
  $ip_names = $nics.map |$nic| { $nic['parameters']['properties']['ipConfigurations'][0]['properties']['publicIPAddress']['id'].split('/')[-1] }

  $ips = example::type_instances($proxy, 'azure_public_ip_address', $ip_names)

  # TODO: use add_config
  $targets = $ips.map |$ip| {
    Target.new(
      "winrm://${admin_user}:${admin_password}@${$ip['parameters']['properties']['ipAddress']}",
      ssl => false
    )
  }

  wait_until_available($targets)
  return run_command('hostname', $targets)
}
