plan example::connect(String $admin_password) {
  # TODO: get from apply somehow
  $admin_user = 'testAdmin'
  $vm_names = ['azblogpostvm1', 'azblogpostvm2']

  # TODO: Resource queries should also act through the proxy, so they need to be tasks
  $vms = $vm_names.map |$name| { query_resource('azure_virtual_machine', $name) }
  $nic_names = $vms.map |$vm| { $vm['properties']['networkProfile']['networkInterfaces'][0]['id'].split('/')[-1] }

  $nics = $nic_names.map |$name| { query_resource('azure_network_interface', $name) }
  $ip_names = $nics.map |$nic| { $nic['properties']['ipConfigurations'][0]['properties']['publicIPAddress']['id'].split('/')[-1] }

  $ips = $ip_names.map |$ip| { query_resource('azure_public_ip_address', $ip) }

  $targets = $ips.map |$ip| {
    Target.new(
      "winrm://${admin_user}:${admin_password}@${$ip['properties']['ipAddress']}",
      ssl => false
    )
  }

  10.each |$_idx| {
    $result = run_command('hostname', $targets, _catch_errors => true)
    if $result.ok {
      return $result
    }
  }
}
