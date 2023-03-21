class Instance < Inspec.resource(1)
  name 'instance'

  desc '
    Instance properties
  '
  example '
    instance.graphic?
  '

  def head_node?
    inspec.node['cluster']['node_type'] == 'HeadNode'
  end

  def compute_node?
    inspec.node['cluster']['node_type'] == 'ComputeFleet'
  end

  def graphic?
    !inspec.command("lspci | grep -i -o 'NVIDIA'").stdout.strip.empty?
  end
end
