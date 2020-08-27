# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: _prep_env
#
# Copyright 2013-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# Determine cfn_scheduler_slots settings and update cfn_instance_slots appropriately
node.default['cfncluster']['cfn_instance_slots'] = if node['cfncluster']['cfn_scheduler_slots'] == 'vcpus'
                                                     node['cpu']['total']
                                                   elsif node['cfncluster']['cfn_scheduler_slots'] == 'cores'
                                                     node['cpu']['total'].fdiv(2).ceil
                                                   else
                                                     node['cfncluster']['cfn_scheduler_slots']
                                                   end

# Setup directories
directory '/etc/parallelcluster'
directory '/opt/parallelcluster'
directory '/opt/parallelcluster/scripts'
directory node['cfncluster']['base_dir']
directory node['cfncluster']['sources_dir']
directory node['cfncluster']['scripts_dir']
directory node['cfncluster']['license_dir']

# Create ParallelCluster log folder
directory '/var/log/parallelcluster/' do
  owner 'root'
  mode '1777'
  recursive true
end

template '/etc/parallelcluster/cfnconfig' do
  source 'cfnconfig.erb'
  mode '0644'
end

link '/opt/parallelcluster/cfnconfig' do
  to '/etc/parallelcluster/cfnconfig'
end

template "/opt/parallelcluster/scripts/fetch_and_run" do
  source 'fetch_and_run.erb'
  owner "root"
  group "root"
  mode "0755"
end

template '/opt/parallelcluster/scripts/compute_ready' do
  source 'compute_ready.erb'
  owner "root"
  group "root"
  mode "0755"
end

include_recipe "aws-parallelcluster::_setup_python"

# Install cloudwatch, write configuration and start it.
include_recipe "aws-parallelcluster::cloudwatch_agent_config"

# retrieve compute and master node info from dynamodb and save into files
if node['cfncluster']['cfn_scheduler'] == 'slurm' && node['cfncluster']['cfn_node_type'] == "ComputeFleet"

  # Ensure slurm plugin directory is in place
  directory "#{node['cfncluster']['slurm_plugin_dir']}" do
    user 'slurm'
    group 'slurm'
    mode '0755'
    action :create
    recursive true
  end

  ruby_block "retrieve compute node info" do
    block do
      slurm_nodename, master_private_ip, master_private_dns = hit_dynamodb_info
      node.run_state['slurm_nodename'] = slurm_nodename
      node.run_state['cfn_master'] = master_private_dns
      node.run_state['cfn_master_private_ip'] = master_private_ip
    end
    retries 5
    retry_delay 3
  end

  file "#{node['cfncluster']['slurm_plugin_dir']}/slurm_nodename" do
    content(lazy { node.run_state['slurm_nodename'] })
    mode '0644'
    owner 'root'
    group 'root'
  end

  file "#{node['cfncluster']['slurm_plugin_dir']}/master_private_dns" do
    content(lazy { node.run_state['cfn_master'] })
    mode '0644'
    owner 'root'
    group 'root'
  end

  file "#{node['cfncluster']['slurm_plugin_dir']}/master_private_ip" do
    content(lazy { node.run_state['cfn_master_private_ip'] })
    mode '0644'
    owner 'root'
    group 'root'
  end
end

# Configure hostname and DNS
include_recipe "aws-parallelcluster::dns_config"
