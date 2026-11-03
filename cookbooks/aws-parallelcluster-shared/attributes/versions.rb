# Python Version
default['cluster']['python-version'] = '3.14.8'
default['cluster']['python-major-minor-version'] = '3.14'

# Test mode: install Python and dependencies from internet instead of pre-built S3 packages
# Set to true when testing new Python versions before artifacts are available in S3
default['cluster']['install_python_from_internet'] = false

# Opt-out: install the aws-parallelcluster-node package from PyPI instead of the
# official S3 bucket.
default['cluster']['install_node_from_internet'] = false

# ParallelCluster versions
default['cluster']['parallelcluster-version'] = '3.16.3'
default['cluster']['parallelcluster-cookbook-version'] = '3.16.3'
default['cluster']['parallelcluster-node-version'] = '3.16.3'

default['cluster']['official_node_package'] = "#{node['cluster']['s3_url']}/parallelcluster/#{node['cluster']['parallelcluster-node-version']}/node/aws-parallelcluster-node-#{node['cluster']['parallelcluster-node-version']}.tgz"

# Base URL (https:// or s3://) of the bundles of Python wheels installed in the ParallelCluster virtualenvs
# (pypi-<type>-dependencies-<python major.minor>-<arch>.tgz under <base url>/<arch>/).
# Each release publishes its own bundles, so that updating them does not change the content of older releases.
# They do not exist before the release, so installing an unreleased version requires overriding this attribute:
# development builds stage the bundles elsewhere (s3://), Kitchen tests use the bundles shared by all the versions
# using the same Python major.minor version (published by the releases before 3.16.3).
default['cluster']['pypi_dependencies_base_url'] = if node['kitchen']
                                                     "#{node['cluster']['artifacts_s3_url']}/dependencies/PyPi"
                                                   else
                                                     "#{node['cluster']['s3_url']}/parallelcluster/#{node['cluster']['parallelcluster-version']}/dependencies/PyPi"
                                                   end
