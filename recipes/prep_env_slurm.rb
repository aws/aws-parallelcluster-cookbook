# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: prep_env_slurm
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

# Ensure slurm plugin directory is in place
# Directory will contain slurm_nodename file used to identify current compute node in computemgtd
directory "#{node['cfncluster']['slurm_plugin_dir']}" do
  user 'root'
  group 'root'
  mode '0755'
  action :create
  recursive true
end

# Retrieve compute and master node info from dynamodb and save into files
if node['cfncluster']['cfn_node_type'] == "ComputeFleet"

  ruby_block "retrieve compute node info" do
    block do
      slurm_nodename, master_private_ip, master_private_dns = hit_dynamodb_info
      node.run_state['slurm_nodename'] = slurm_nodename
      node.run_state['cfn_master'] = master_private_dns
      node.run_state['cfn_master_private_ip'] = master_private_ip
    end
    retries 5
    retry_delay 3
    not_if node.run_state['slurm_nodename'] && node.run_state['cfn_master'] && node.run_state['cfn_master_private_ip']
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
