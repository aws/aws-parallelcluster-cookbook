default['cluster']['base_dir'] = '/opt/parallelcluster'
default['cluster']['sources_dir'] = "#{node['cluster']['base_dir']}/sources"
default['cluster']['scripts_dir'] = "#{node['cluster']['base_dir']}/scripts"
default['cluster']['license_dir'] = "#{node['cluster']['base_dir']}/licenses"
default['cluster']['configs_dir'] = "#{node['cluster']['base_dir']}/configs"
default['cluster']['shared_dir'] = "#{node['cluster']['base_dir']}/shared"

# plcuster-specific pyenv system installation root
default['cluster']['system_pyenv_root'] = "#{node['cluster']['base_dir']}/pyenv"

default['cluster']['cluster_config_path'] = "#{node['cluster']['shared_dir']}/cluster-config.yaml"
default['cluster']['previous_cluster_config_path'] = "#{node['cluster']['shared_dir']}/previous-cluster-config.yaml"
default['cluster']['change_set_path'] = "#{node['cluster']['shared_dir']}/change-set.json"
default['cluster']['launch_templates_config_path'] = "#{node['cluster']['shared_dir']}/launch-templates-config.json"
default['cluster']['instance_types_data_path'] = "#{node['cluster']['shared_dir']}/instance-types-data.json"

default['cluster']['scheduler'] = 'slurm'
default['cluster']['node_type'] = nil
