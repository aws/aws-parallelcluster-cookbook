default['cluster']['base_dir'] = '/opt/parallelcluster'
default['cluster']['sources_dir'] = "#{node['cluster']['base_dir']}/sources"
default['cluster']['scripts_dir'] = "#{node['cluster']['base_dir']}/scripts"
default['cluster']['license_dir'] = "#{node['cluster']['base_dir']}/licenses"
default['cluster']['configs_dir'] = "#{node['cluster']['base_dir']}/configs"
default['cluster']['shared_dir'] = "#{node['cluster']['base_dir']}/shared"
default['cluster']['shared_login_nodes_dir'] = "#{node['cluster']['base_dir']}/shared_login_nodes"
default['cluster']['log_base_dir'] = '/var/log/parallelcluster'
default['cluster']['etc_dir'] = '/etc/parallelcluster'

# Slurm_plugin_dir is used by slurm cookbook and custom_actions recipe
default['cluster']['slurm_plugin_dir'] = "#{node['cluster']['etc_dir']}/slurm_plugin"

# Attributes used by both fetch_config resource and environment recipes
default['cluster']['shared_storages_mapping_path'] = "#{node['cluster']['etc_dir']}/shared_storages_data.yaml"
default['cluster']['previous_shared_storages_mapping_path'] = "#{node['cluster']['etc_dir']}/previous_shared_storages_data.yaml"

# plcuster-specific pyenv system installation root
default['cluster']['system_pyenv_root'] = "#{node['cluster']['base_dir']}/pyenv"

default['cluster']['cluster_config_path'] = "#{node['cluster']['shared_dir']}/cluster-config.yaml"
default['cluster']['previous_cluster_config_path'] = "#{node['cluster']['shared_dir']}/previous-cluster-config.yaml"
default['cluster']['change_set_path'] = "#{node['cluster']['shared_dir']}/change-set.json"
default['cluster']['instance_types_data_path'] = "#{node['cluster']['shared_dir']}/instance-types-data.json"

default['cluster']['scheduler'] = 'slurm'
default['cluster']['node_type'] = nil

default['cluster']["directory_service"]["enabled"] = 'false'

# Default NFS mount options
default['cluster']['nfs']['hard_mount_options'] = 'hard,_netdev,noatime'
