# Python Version
default['cluster']['python-version'] = '3.14.6'
default['cluster']['python-major-minor-version'] = '3.14'

# Test mode: install Python and dependencies from internet instead of pre-built S3 packages
# Set to true when testing new Python versions before artifacts are available in S3
default['cluster']['install_python_from_internet'] = false

# Opt-out: install the aws-parallelcluster-node package from PyPI instead of the
# official S3 bucket.
default['cluster']['install_node_from_internet'] = false

# ParallelCluster versions
default['cluster']['parallelcluster-version'] = '3.16.0'
default['cluster']['parallelcluster-cookbook-version'] = '3.16.0'
default['cluster']['parallelcluster-node-version'] = '3.16.0'

default['cluster']['official_node_package'] = "#{node['cluster']['s3_url']}/parallelcluster/#{node['cluster']['parallelcluster-node-version']}/node/aws-parallelcluster-node-#{node['cluster']['parallelcluster-node-version']}.tgz"
