# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-slurm
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

return unless node['cluster']['scheduler'] == 'slurm'

# Ensure slurm plugin directory is in place
# Directory will contain slurm_nodename file used to identify current compute node in computemgtd
directory node['cluster']['slurm_plugin_dir'] do
  user 'root'
  group 'root'
  mode '0755'
  action :create
  recursive true
end

# Retrieve compute info from dynamodb and save into file
if node['cluster']['node_type'] == "ComputeFleet"

  ruby_block "retrieve compute node info" do
    block do
      slurm_nodename = dynamodb_info
      node.force_default['cluster']['slurm_nodename'] = slurm_nodename
    end
    not_if do
      !node['cluster']['slurm_nodename'].nil? && !node['cluster']['slurm_nodename'].empty?
    end
  end

  file "#{node['cluster']['slurm_plugin_dir']}/slurm_nodename" do
    content(lazy { node['cluster']['slurm_nodename'] })
    mode '0644'
    owner 'root'
    group 'root'
  end

  template "#{node['cluster']['slurm_plugin_dir']}/slurm_node_spec.json" do
    source 'slurm/compute/slurm_node_spec.json.erb'
    owner "root"
    group "root"
    mode "0644"
    variables(
      region: node['cluster']['region'],
      cluster_name: node['cluster']['cluster_name'] || node['cluster']['stack_name'],
      scheduler: node['cluster']['scheduler'],
      node_role: "ComputeFleet",
      queue_name: node['cluster']['scheduler_queue_name'],
      compute_resource: node['cluster']['scheduler_compute_resource_name'],
      node_name: lazy { node['cluster']['slurm_nodename'] },
      node_type: lazy { is_static_node?(node['cluster']['slurm_nodename']) ? "static" : "dynamic" },
      instance_id: node['ec2']['instance_id'],
      instance_type: node['ec2']['instance_type'],
      availability_zone: node['ec2']['availability_zone'],
      ip_address: node['ipaddress'],
      hostname: node['ec2']['hostname']
    )
  end
end

# Configure hostname and DNS
include_recipe "aws-parallelcluster-slurm::init_dns" unless on_docker?
