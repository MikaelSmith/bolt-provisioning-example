plan example::query(
  String $type,
  Optional[String] $name=undef
) {
  if $name {
    return query_resource($type, $name)
  }
  else {
    return query_resource($type)
  }
}
