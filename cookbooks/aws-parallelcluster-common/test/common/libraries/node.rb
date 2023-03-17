class ::Hash
  def deep_merge(second)
    merger = proc { |_key, v1, v2| v1.is_a?(Hash) && v2.is_a?(Hash) ? v1.merge(v2, &merger) : v2 }
    merge(second, &merger)
  end
end

class Node < Inspec.resource(1)
  name 'node'

  desc '
    Node properties
  '
  example "
    node.node['cluster']['cluster_admin_user']
  "

  def initialize
    @params = {}
    @params = inspec.json('/etc/chef/node_attributes.json')
    # https://docs.chef.io/attribute_precedence/
    @node = @params['default'].deep_merge(@params['normal']).deep_merge(@params['override']).deep_merge(@params['automatic'])
  end

  def [](key)
    @node[key]
  end
end
