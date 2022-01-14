# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-scheduler-plugin
# Recipe:: config_head_node
#
# Copyright:: 2013-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

directory '/etc/parallelcluster/scheduler_plugin'

template "/etc/parallelcluster/scheduler_plugin/clusterstatusmgtd.conf" do
  source 'clusterstatusmgtd/clusterstatusmgtd.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

execute_event_handler 'HeadConfigure' do
  event_command(lazy { node['cluster']['config'].dig(:Scheduling, :SchedulerSettings, :SchedulerDefinition, :Events, :HeadConfigure, :ExecuteCommand, :Command) })
end

cookbook_file "#{node['cluster']['scripts_dir']}/compute_fleet_status.py" do
  source 'compute_fleet_status/compute_fleet_status.py'
  owner 'root'
  group 'root'
  mode '0755'
  not_if { ::File.exist?("#{node['cluster']['scripts_dir']}/compute_fleet_status.py") }
end

template "/usr/local/bin/update-compute-fleet-status.sh" do
  source 'compute_fleet_status/update-compute-fleet-status.erb'
  owner 'root'
  group 'root'
  mode '0755'
end

template "/usr/local/bin/get-compute-fleet-status.sh" do
  source 'compute_fleet_status/get-compute-fleet-status.erb'
  owner 'root'
  group 'root'
  mode '0755'
end
