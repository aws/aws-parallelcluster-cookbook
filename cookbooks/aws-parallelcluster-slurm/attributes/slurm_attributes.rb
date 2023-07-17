# URLs to software packages used during install recipes
default['cluster']['slurm']['fleet_config_path'] = "#{node['cluster']['slurm_plugin_dir']}/fleet-config.json"

# Slurm attributes shared between install_slurm and configure_slurm_accounting
default['cluster']['slurm']['commit'] = ''
default['cluster']['slurm']['sha256'] = 'c41747e4484011cf376d6d4bc73b6c4696cdc0f7db4f64174f111bb9f53fb603'
default['cluster']['slurm']['install_dir'] = '/opt/slurm'

default['cluster']['dns_domain'] = nil
default['cluster']['use_private_hostname'] = 'false'

default['cluster']['realmemory_to_ec2memory_ratio'] = 0.95
default['cluster']['slurm_node_reg_mem_percent'] = 75
default['cluster']['slurmdbd_response_retries'] = 30
default['cluster']['slurm_plugin_console_logging']['sample_size'] = 1
default["cluster"]["scheduler_compute_resource_name"] = nil

default['cluster']['enable_nss_slurm'] = node['cluster']['directory_service']['enabled']
