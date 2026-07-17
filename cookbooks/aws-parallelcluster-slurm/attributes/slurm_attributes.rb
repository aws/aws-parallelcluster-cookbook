# URLs to software packages used during install recipes
default['cluster']['slurm']['fleet_config_path'] = "#{node['cluster']['slurm_plugin_dir']}/fleet-config.json"

default['cluster']['dns_domain'] = nil
default['cluster']['use_private_hostname'] = 'false'

default['cluster']['realmemory_to_ec2memory_ratio'] = 0.95
default['cluster']['slurm_node_reg_mem_percent'] = 75
default['cluster']['slurmdbd_response_retries'] = 30
default['cluster']['slurm_plugin_console_logging']['sample_size'] = 1
default["cluster"]["scheduler_compute_resource_name"] = nil

default['cluster']['enable_nss_slurm'] = node['cluster']['directory_service']['enabled']

# PMIX Version and Checksum
default['cluster']['pmix']['version'] = '5.0.11'
default['cluster']['pmix']['sha256'] = '11d91183c4fd77117d9e7f186a1f4fde182895314b18fc5783fee7e2e5595e88'
default['cluster']['pmix']['base_url'] = "#{node['cluster']['artifacts_s3_url']}/dependencies/pmix"

# Slurmdbd
default['cluster']['slurmdbd_service_enabled'] = "true"

# Spank
default['cluster']['slurm']['spank_config_dir'] = "#{node['cluster']['slurm']['install_dir']}/etc/plugstack.conf.d"

# Pyxis
default['cluster']['pyxis']['version'] = '0.24.0'
default['cluster']['pyxis']['base_url'] = "#{node['cluster']['artifacts_s3_url']}/dependencies/pyxis"
default['cluster']['pyxis']['runtime_path'] = '/run/pyxis'

# HTTP Parser (only needed on AL2023)
default['cluster']['http_parser']['version'] = '2.9.4'
default['cluster']['http_parser']['base_url'] = "#{node['cluster']['artifacts_s3_url']}/dependencies/http_parser"

# Block Topology Plugin
default['cluster']['slurm']['block_topology']['force_configuration'] = false
default['cluster']['p6egb200_block_sizes'] = nil

# Slurm Reconfigure
default['cluster']['slurm']['reconfigure_timeout'] = 300 # seconds
