# Uses a proxy to query a set of instances of a resource type and returns an array of those resources.
function example::type_instances(TargetSpec $proxy, String $type, Array[String] $instances) >> Array[Hash] {
  $instance_refs = $instances.map |$name| { "$type[${name}]" }
  $resources = get_resources($proxy, $instance_refs).map |$result| { $result['resources'] }.flatten
  $missing = $resources.filter |$resource| { $resource['parameters']['ensure'] == 'absent' }
  if !$missing.empty {
    fail_plan("Resource ${type} instances ${missing} do not exist")
  }
  $resources
}
