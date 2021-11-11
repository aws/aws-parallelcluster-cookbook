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

# NOTE: this recipe must be included after instance_slot because it may alter the values of
#       node['cpu']['total'], which would break the expected behavior when setting scheduler_slots
#       to one of the constants looked for in the above conditionals
include_recipe "aws-parallelcluster-config::disable_hyperthreading"

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

# Install cloudwatch, write configuration and start it.
include_recipe "aws-parallelcluster-config::cloudwatch_agent"

# Configure additional Networking Interfaces (if present)
include_recipe "aws-parallelcluster-config::network_interfaces" unless virtualized?

include_recipe "aws-parallelcluster-config::mount_shared" if node['cluster']['node_type'] == "ComputeFleet"

include_recipe "aws-parallelcluster-config::fetch_config" unless node['cluster']['scheduler'] == 'awsbatch'

include_recipe "aws-parallelcluster-slurm::init" if node['cluster']['scheduler'] == 'slurm'
include_recipe "aws-parallelcluster-scheduler-plugin::init" if node['cluster']['scheduler'] == 'plugin'

# IMDS
include_recipe 'aws-parallelcluster-config::imds' unless virtualized?

# Active Directory Service
include_recipe "aws-parallelcluster-config::directory_service"
