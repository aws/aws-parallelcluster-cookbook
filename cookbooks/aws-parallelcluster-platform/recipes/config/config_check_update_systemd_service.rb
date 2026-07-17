# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-platform
# Recipe:: config_check_update_systemd_service
#
# Copyright:: 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

template "#{node['cluster']['scripts_dir']}/pcluster-check-update.sh" do
  source 'check_update/pcluster-check-update.sh.erb'
  owner 'root'
  group 'root'
  mode '0755'
end

template '/etc/systemd/system/pcluster-check-update.service' do
  source 'check_update/pcluster-check-update.service.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

cookbook_file '/etc/systemd/system/pcluster-check-update.timer' do
  source 'check_update/pcluster-check-update.timer'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

file node['cluster']['update']['trigger_file'] do
  content ''
  owner 'root'
  group 'root'
  mode '0644'
  action :create_if_missing
end

file node['cluster']['update']['checkpoint_file'] do
  content ''
  owner 'root'
  group 'root'
  mode '0644'
  action :create_if_missing
end

# Create log file so CloudWatch agent can monitor it before the service runs
file "#{node['cluster']['log_base_dir']}/pcluster-check-update.log" do
  content ''
  owner 'root'
  group 'root'
  mode '0644'
  action :create_if_missing
end

template "#{node['cluster']['scripts_dir']}/cluster-update-action.sh" do
  source 'check_update/cluster-update-action.sh.erb'
  owner 'root'
  group 'root'
  mode '0700'
  variables(
    monitor_shared_dir: node['cluster']['update']['dna_dir'],
    launch_template_resource_id: node['cluster']['launch_template_id'],
    exec_tmp_dir: node['cluster']['exec_tmp_dir']
  )
end
