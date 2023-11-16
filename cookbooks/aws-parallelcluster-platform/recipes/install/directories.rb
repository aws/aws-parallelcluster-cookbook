#
# Cookbook:: aws-parallelcluster-platform
# Recipe:: directories
#
# Copyright:: 2013-2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# Setup directories
directory node['cluster']['etc_dir']
directory node['cluster']['base_dir']
directory node['cluster']['sources_dir']
directory node['cluster']['scripts_dir']
directory node['cluster']['license_dir']
directory node['cluster']['configs_dir']
directory node['cluster']['shared_dir']
directory node['cluster']['shared_dir_login_nodes']

# Create ParallelCluster log folder
directory node['cluster']['log_base_dir'] do
  owner 'root'
  mode '1777'
  recursive true
end
