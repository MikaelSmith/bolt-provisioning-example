plan example(TargetSpec $proxy = 'local://', String $admin_user, String $admin_password) {
  if get_targets($proxy).size != 1 {
    fail("Must specify a single proxy, not ${proxy}")
  }
  apply($proxy) {
    class { 'example':
      admin_user     => $admin_user,
      admin_password => $admin_password,
    }
  }

  # The machines take awhile to start, and Azure's eventual consistency means we occasionally don't immediately
  # get the expected state back. Add a sleep to allow for them to show up.
  example::sleep(5)
  return run_plan('example::connect', proxy => $proxy, admin_user => $admin_user, admin_password => $admin_password)
}
