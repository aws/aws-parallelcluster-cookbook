# frozen_string_literal: true
#
# Copyright:: 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

unified_mode true
default_action :configure

action :configure do
  return unless is_block_topology_supported?
  # Use slurm_parallelcluster_topology to add Block Topology plugin
  template "#{node['cluster']['slurm']['install_dir']}/etc/slurm_parallelcluster_topology.conf" do
    source 'slurm/block_topology/slurm_parallelcluster_topology.conf.erb'
    owner 'root'
    group 'root'
    mode '0644'
  end
  # Generate Slurm topology.conf file
  execute "generate_topology_config" do
    command "#{cookbook_virtualenv_path}/bin/python #{node['cluster']['scripts_dir']}/slurm/pcluster_topology_generator.py"\
              " --output-file #{node['cluster']['slurm']['install_dir']}/etc/topology.conf"\
              " --block-sizes #{node['cluster']['p6egb200_block_sizes']}"\
              " --input-file #{node['cluster']['cluster_config_path']}"
    not_if { node['cluster']['p6egb200_block_sizes'].nil? }
  end
end

action :update do
  return unless is_block_topology_supported?
  # Update slurm_parallelcluster_topology to add/remove Block Topology plugin
  template "#{node['cluster']['slurm']['install_dir']}/etc/slurm_parallelcluster_topology.conf" do
    source 'slurm/block_topology/slurm_parallelcluster_topology.conf.erb'
    owner 'root'
    group 'root'
    mode '0644'
  end
  # Update Slurm topology.conf file
  execute "update or cleanup topology.conf" do
    command "#{cookbook_virtualenv_path}/bin/python #{node['cluster']['scripts_dir']}/slurm/pcluster_topology_generator.py"\
              " --output-file #{node['cluster']['slurm']['install_dir']}/etc/topology.conf"\
              " --input-file #{node['cluster']['cluster_config_path']}"\
              "#{topology_generator_command_args}"
    not_if { ::File.exist?(node['cluster']['previous_cluster_config_path']) && topology_generator_command_args.nil? }
  end
end

def is_block_topology_supported?
  true
end

def topology_generator_command_args
  if node['cluster']['p6egb200_block_sizes'].nil? && are_queues_updated? && ::File.exist?("#{node['cluster']['slurm']['install_dir']}/etc/topology.conf")
    # If topology.conf exist and Capacity Block is removed, we cleanup
    " --cleanup"
  elsif node['cluster']['p6egb200_block_sizes'].nil? && !are_queues_updated?
    # We do nothing if p6e-gb200 is not used and queues are not updated
    nil
  else
    " --block-sizes #{node['cluster']['p6egb200_block_sizes']}"
  end
end
