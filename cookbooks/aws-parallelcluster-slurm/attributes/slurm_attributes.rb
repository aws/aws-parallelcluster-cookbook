# URLs to software packages used during install recipes
default['cluster']['slurm']['fleet_config_path'] = "#{node['cluster']['slurm_plugin_dir']}/fleet-config.json"

# Slurm attributes shared between install_slurm and configure_slurm_accounting
default['cluster']['slurm']['commit'] = ''
default['cluster']['slurm']['branch'] = 'slurm-23.02'
default['cluster']['slurm']['sha256'] = '4fee743a34514d8fe487080048256f5ee032374ed5f42d0eae342110dcd59edf'
default['cluster']['slurm']['install_dir'] = '/opt/slurm'

default['cluster']['dns_domain'] = nil
default['cluster']['use_private_hostname'] = 'false'

default['cluster']['realmemory_to_ec2memory_ratio'] = 0.95
default['cluster']['slurm_node_reg_mem_percent'] = 75
default['cluster']['slurmdbd_response_retries'] = 30
default['cluster']['slurm_plugin_console_logging']['sample_size'] = 1
default["cluster"]["scheduler_compute_resource_name"] = nil

default['cluster']['enable_nss_slurm'] = node['cluster']['directory_service']['enabled']
