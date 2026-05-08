# Python Version
default['cluster']['python-version'] = '3.14.2'
default['cluster']['python-major-minor-version'] = '3.14'
if platform?('amazon') && node['platform_version'] == "2"
  default['cluster']['python-version'] = '3.9.23'
  default['cluster']['python-major-minor-version'] = '3.9'
end

# Test mode: install Python and dependencies from internet instead of pre-built S3 packages
# Set to true when testing new Python versions before artifacts are available in S3
default['cluster']['install_python_from_internet'] = false

# ParallelCluster versions
default['cluster']['parallelcluster-version'] = '3.15.1'
default['cluster']['parallelcluster-cookbook-version'] = '3.15.1'
default['cluster']['parallelcluster-node-version'] = '3.15.1'
default['cluster']['parallelcluster-awsbatch-cli-version'] = '1.6.0'
