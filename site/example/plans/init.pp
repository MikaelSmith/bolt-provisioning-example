plan example(String $admin_password) {
  return apply('local://') {
    class { 'example': admin_password => $admin_password }
  }
}
