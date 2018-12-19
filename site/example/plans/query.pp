plan example::query(
  TargetSpec $proxy = 'local://',
  String $type_ref,
) {
  return get_resources($proxy, $type_ref)
}
