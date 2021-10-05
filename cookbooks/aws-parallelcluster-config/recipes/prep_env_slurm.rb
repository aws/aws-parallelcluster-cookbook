# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: prep_env_slurm
#
# Copyright 2013-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
directory node['cluster']['slurm_plugin_dir'] do
  user 'root'
  group 'root'
  mode '0755'
  action :create
  recursive true
end

# Retrieve compute and head node info from dynamodb and save into files
if node['cluster']['node_type'] == "ComputeFleet"

  ruby_block "retrieve compute node info" do
    block do
      slurm_nodename, head_node_private_ip, head_node_private_dns = hit_dynamodb_info
      node.force_default['cluster']['slurm_nodename'] = slurm_nodename
      node.force_default['cluster']['head_node'] = head_node_private_dns
      node.force_default['cluster']['head_node_private_ip'] = head_node_private_ip
    end
    retries 5
    retry_delay 3
    not_if do
      !node['cluster']['slurm_nodename'].nil? && !node['cluster']['slurm_nodename'].empty? &&
        !node['cluster']['head_node'].nil? && !node['cluster']['head_node'].empty? &&
        !node['cluster']['head_node_private_ip'].nil? && !node['cluster']['head_node_private_ip'].empty?
    end
  end

  file "#{node['cluster']['slurm_plugin_dir']}/slurm_nodename" do # ~FC005
    content(lazy { node['cluster']['slurm_nodename'] })
    mode '0644'
    owner 'root'
    group 'root'
  end

  file "#{node['cluster']['slurm_plugin_dir']}/head_node_private_dns" do
    content(lazy { node['cluster']['head_node'] })
    mode '0644'
    owner 'root'
    group 'root'
  end

  file "#{node['cluster']['slurm_plugin_dir']}/head_node_private_ip" do
    content(lazy { node['cluster']['head_node_private_ip'] })
    mode '0644'
    owner 'root'
    group 'root'
  end
end
