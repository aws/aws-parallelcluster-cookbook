default['cluster']['computefleet_status_path'] = "#{node['cluster']['shared_dir']}/computefleet-status.json"

# Compute nodes bootstrap timeout
default['cluster']['compute_node_bootstrap_timeout'] = 1800

# Time budget (seconds) for retrieving EC2 instance info after a CreateFleet launch, to tolerate
# EC2 API eventual consistency.
default['cluster']['compute_instance_info_timeout'] = 90
