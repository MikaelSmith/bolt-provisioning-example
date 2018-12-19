plan example::connect(TargetSpec $proxy = 'local://', String $admin_user, String $admin_password) {
  # TODO: get from apply somehow
  $vm_names = ['azblogpostvm1', 'azblogpostvm2']

  $vm_refs = $vm_names.map |$name| { "azure_virtual_machine[${name}]" }
  $vms = get_resources($proxy, $vm_refs).first['resources']
  if $vms[0]['parameters']['ensure'] == 'absent' {
      fail_plan("VMs ${vm_names} do not exist")
  }
  $nic_names = $vms.map |$vm| { $vm['parameters']['properties']['networkProfile']['networkInterfaces'][0]['id'].split('/')[-1] }

  $nic_refs = $nic_names.map |$name| { "azure_network_interface[${name}]" }
  $nics = get_resources($proxy, $nic_refs).first['resources']
  $ip_names = $nics.map |$nic| { $nic['parameters']['properties']['ipConfigurations'][0]['properties']['publicIPAddress']['id'].split('/')[-1] }

  $ip_refs = $ip_names.map |$name| { "azure_public_ip_address[${name}]" }
  $ips = get_resources($proxy, $ip_refs).first['resources']

  $targets = $ips.map |$ip| {
    Target.new(
      "winrm://${admin_user}:${admin_password}@${$ip['parameters']['properties']['ipAddress']}",
      ssl => false
    )
  }

  wait_until_available($targets)
  return run_command('hostname', $targets)
}
