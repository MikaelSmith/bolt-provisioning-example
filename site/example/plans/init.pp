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

  return run_plan('example::connect', admin_password => $admin_password)
}
