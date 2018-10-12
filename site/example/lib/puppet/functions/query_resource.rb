# frozen_string_literal: true

require 'puppet'

Puppet::Functions.create_function(:query_resource) do
  dispatch :instances do
    param 'String', :type
    return_type 'Array[Hash[String, Data]]'
  end

  dispatch :instance do
    param 'String', :type
    param 'String', :name
    return_type 'Hash[String, Data]'
  end

  def stringify_resource(resource)
    resource.to_hash.each_with_object({}) do |(k, v), hsh|
      hsh[k.to_s] = (v.is_a?(Symbol) ? v.to_s : v)
    end
  end

  def instances(type_name)
    resources = Puppet::Resource.indirection.search(type_name, {})
    resources.map do |resource|
      stringify_resource(resource)
    end
  end

  def instance(type_name, resource_name)
    resource = Puppet::Resource.indirection.find("#{type_name}/#{resource_name}")
    stringify_resource(resource)
  end
end

