# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-slurm
# Recipe:: config_head_node_directories
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

# Ensure config directory is in place
directory "#{node['cluster']['slurm']['install_dir']}" do
  user 'root'
  group 'root'
  mode '0755'
end

# Ensure config directory is in place
directory "#{node['cluster']['slurm']['install_dir']}/etc" do
  user 'root'
  group 'root'
  mode '0755'
end

# Create directory configured as StateSaveLocation
directory '/var/spool/slurm.state' do
  user node['cluster']['slurm']['user']
  group node['cluster']['slurm']['group']
  mode '0700'
end

# Copy pcluster config generator and templates
remote_directory "#{node['cluster']['scripts_dir']}/slurm" do
  source 'head_node_slurm/slurm'
  mode '0755'
  action :create
  recursive true
end

# Copy pcluster scripts to execute cluster health checks
remote_directory "#{node['cluster']['scripts_dir']}/head_node_checks" do
  source 'head_node_checks'
  mode '0755'
  owner 'root'
  group 'root'
  recursive true
end
