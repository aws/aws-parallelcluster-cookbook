# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-config
# Recipe:: init
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

# Validate OS type specified by the user is the same as the OS identified by Ohai
validate_os_type

# Validate init system
raise "Init package #{node['init_package']} not supported." unless systemd?

# Determine scheduler_slots settings and update instance_slots appropriately
node.default['cluster']['instance_slots'] = case node['cluster']['scheduler_slots']
                                            when 'vcpus'
                                              node['cpu']['total']
                                            when 'cores'
                                              node['cpu']['cores']
                                            else
                                              node['cluster']['scheduler_slots']
                                            end

template '/etc/parallelcluster/cfnconfig' do
  source 'init/cfnconfig.erb'
  mode '0644'
end

link '/opt/parallelcluster/cfnconfig' do
  to '/etc/parallelcluster/cfnconfig'
end

template "/opt/parallelcluster/scripts/fetch_and_run" do
  source 'init/fetch_and_run.erb'
  owner "root"
  group "root"
  mode "0755"
end

cookbook_file '/etc/sudoers.d/99-parallelcluster-env-keep' do
  source 'sudoers/99-parallelcluster-env-keep'
  owner 'root'
  group 'root'
  mode '0600'
  only_if { node['cluster']['region'].start_with?('us-iso') }
end

include_recipe "aws-parallelcluster-config::mount_shared" if node['cluster']['node_type'] == "ComputeFleet"

fetch_config 'Fetch and load cluster configs' unless node['cluster']['scheduler'] == 'awsbatch'

# Install cloudwatch, write configuration and start it.
include_recipe "aws-parallelcluster-config::cloudwatch_agent"

# Configure additional Networking Interfaces (if present)
include_recipe "aws-parallelcluster-config::network_interfaces" unless virtualized?

# Cluster Status Management Demon
if node['cluster']['node_type'] == 'HeadNode'
  unless node['cluster']['scheduler'] == 'awsbatch'
    # create placeholder for computefleet-status.json, so it can be written by clusterstatusmgtd which run as pcluster admin user
    file node['cluster']['computefleet_status_path'] do
      owner node['cluster']['cluster_admin_user']
      group node['cluster']['cluster_admin_user']
      content '{}'
      mode '0755'
      action :create
    end

    # create sudoers entry to let pcluster admin user execute update compute fleet recipe
    template '/etc/sudoers.d/99-parallelcluster-clusterstatusmgtd' do
      source 'clusterstatusmgtd/99-parallelcluster-clusterstatusmgtd.erb'
      owner 'root'
      group 'root'
      mode '0600'
    end

    # create log file for clusterstatusmgtd
    file "/var/log/parallelcluster/clusterstatusmgtd" do
      owner 'root'
      group 'root'
      mode '0640'
    end
  end
end

include_recipe "aws-parallelcluster-slurm::init" if node['cluster']['scheduler'] == 'slurm'
include_recipe "aws-parallelcluster-scheduler-plugin::init" if node['cluster']['scheduler'] == 'plugin'

# IMDS
include_recipe 'aws-parallelcluster-config::imds' unless virtualized?

# Active Directory Service
include_recipe "aws-parallelcluster-config::directory_service"
