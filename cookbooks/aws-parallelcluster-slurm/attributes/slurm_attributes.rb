# URLs to software packages used during install recipes
default['cluster']['slurm_plugin_dir'] = '/etc/parallelcluster/slurm_plugin'
default['cluster']['slurm']['fleet_config_path'] = "#{node['cluster']['slurm_plugin_dir']}/fleet-config.json"

# Slurm attributes shared between install_slurm and configure_slurm_accounting
default['cluster']['slurm']['commit'] = ''
default['cluster']['slurm']['sha256'] = '71edcf187a7d68176cca06143adf98e8f332d42cdf000cb534b03b13834ad537'
default['cluster']['slurm']['install_dir'] = '/opt/slurm'

default['cluster']['dns_domain'] = nil
default['cluster']['use_private_hostname'] = 'false'

default['cluster']['realmemory_to_ec2memory_ratio'] = 0.95
default['cluster']['slurm_node_reg_mem_percent'] = 75
default['cluster']['slurmdbd_response_retries'] = 30
default['cluster']['slurm_plugin_console_logging']['sample_size'] = 1
default["cluster"]["scheduler_compute_resource_name"] = nil

default['cluster']['enable_nss_slurm'] = node['cluster']['directory_service']['enabled']
