# frozen_string_literal: true

require 'puppet'

Puppet::Functions.create_function(:query_resource) do
  dispatch :query do
    param 'String', :type
    return_type 'Array[Hash[String, Data]]'
  end

  def query(type_name)
    type = Puppet::Type.type(type_name)
    type.instances.map(&:to_resource).map do |resource|
      resource.to_hash.each_with_object({}) do |(k, v), hsh|
        hsh[k.to_s] = (v.is_a?(Symbol) ? v.to_s : v)
      end
    end
  end
end

