# load cluster configuration file into node object
def load_cluster_config
  ruby_block "load cluster configuration" do
    block do
      require 'yaml'
      config = YAML.safe_load(File.read(node['cluster']['cluster_config_path']))
      Chef::Log.debug("Config read #{config}")
      node.override['cluster']['config'].merge! config
    end
    only_if { node['cluster']['config'].nil? }
  end
end
