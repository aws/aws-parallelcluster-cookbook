# Python Version
default['cluster']['python-version'] = '3.12.11'
default['cluster']['python-major-minor-version'] = '3.12'
if platform?('amazon') && node['platform_version'] == "2"
  default['cluster']['python-version'] = '3.9.20'
  default['cluster']['python-major-minor-version'] = '3.9'
end

# ParallelCluster versions
default['cluster']['parallelcluster-version'] = '3.14.0'
default['cluster']['parallelcluster-cookbook-version'] = '3.14.0'
default['cluster']['parallelcluster-node-version'] = '3.14.0'
default['cluster']['parallelcluster-awsbatch-cli-version'] = '1.4.0'
