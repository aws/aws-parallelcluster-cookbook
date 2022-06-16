# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-slurm
# Recipe:: update_head_node
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

execute 'stop clustermgtd' do
  command "#{node['cluster']['cookbook_virtualenv_path']}/bin/supervisorctl stop clustermgtd"
  not_if { ::File.exist?(node['cluster']['previous_cluster_config_path']) && !are_queues_updated? }
end

ruby_block "replace slurm queue nodes" do
  SLURM_POWER_SAVING_MAPPING = {
    DRAIN: "POWER_DOWN_ASAP",
    TERMINATE: "POWER_DOWN_FORCE",
  }.freeze

  def get_slurm_nodelist(queue)
    #
    # Example content for a slurm_parallelcluster_#{queue}_partition.conf
    #
    # NodeName=compute1-st-compute1-i1-[1-1] CPUs=16 State=CLOUD Feature=static,c5.4xlarge,compute1-i1
    # NodeName=compute1-dy-compute1-i1-[1-9] CPUs=16 State=CLOUD Feature=dynamic,c5.4xlarge,compute1-i1
    #
    # NodeSet=compute1_nodes Nodes=compute1-st-compute1-i1-[1-1],compute1-dy-compute1-i1-[1-9]
    # PartitionName=compute1 Nodes=compute1_nodes MaxTime=INFINITE State=UP
    #
    command = "sed -n 's/.*NodeSet.*Nodes=\\(.*\\)/\\1/p' #{node['cluster']['slurm']['install_dir']}/etc/pcluster/slurm_parallelcluster_#{queue}_partition.conf"
    Chef::Log.debug("Retrieving nodelist with command (#{command})")
    node_list = execute_command(command)
    Chef::Log.info("Node list for queue (#{queue}) is (#{node_list})")
    node_list
  end

  def update_slurm_nodes(state, nodelist)
    command = "sudo -i scontrol update state=#{state} nodename=#{nodelist} reason='updating node state during cluster update'"
    Chef::Log.info("Executing node state update with command (#{command})")
    execute_command(command)
  end

  def split_static_and_dynamic_nodes(nodelist)
    static_nodes = []
    dynamic_nodes = []
    nodes = nodelist.split(',')
    nodes.each do |node|
      if is_static_node?(node)
        static_nodes.push(node)
      else
        dynamic_nodes.push(node)
      end
    end

    [static_nodes, dynamic_nodes]
  end

  def update_nodes(strategy, nodelist)
    if strategy == "DRAIN"
      static_nodes, dynamic_nodes = split_static_and_dynamic_nodes(nodelist)
      # Set static nodes to DRAIN to keep clustermgtd in charge of managing static nodes lifecycle
      update_slurm_nodes(strategy, static_nodes.join(",")) if static_nodes.any?
      update_slurm_nodes(SLURM_POWER_SAVING_MAPPING[strategy.to_sym], dynamic_nodes.join(",")) if dynamic_nodes.any?
    elsif strategy == "TERMINATE"
      update_slurm_nodes(SLURM_POWER_SAVING_MAPPING[strategy.to_sym], nodelist)
    end
  end

  def get_queues_with_changes
    # Load change set and find queue with changes
    queues = Set.new
    change_set = JSON.load_file("#{node['cluster']['shared_dir']}/change-set.json")
    Chef::Log.debug("Loaded change set (#{change_set})")
    change_set["changeSet"].each do |change|
      next unless change["updatePolicy"] == "QUEUE_UPDATE_STRATEGY"
      queue = change["parameter"][/Scheduling\.SlurmQueues\[([^\]]*)\]/, 1]
      Chef::Log.info("Adding queue (#{queue}) to list of queue to be updated")
      queues.add(queue)
    end
    queues
  end

  def update_nodes_in_queue(strategy, queues)
    # Update state for nodes in queue with changes
    if queues.empty?
      Chef::Log.info("No queue to be replaced found")
    else
      queues.each do |queue|
        node_list = get_slurm_nodelist(queue)
        Chef::Log.info("Updating node state for queue (#{queue})")
        update_nodes(strategy, node_list)
      end
    end
  end

  block do
    # Load queue update strategy from cluster config
    config = YAML.safe_load(File.read(node['cluster']['cluster_config_path']))
    queue_update_strategy = config.dig("Scheduling", "SlurmSettings", "QueueUpdateStrategy")
    Chef::Log.debug("Found queue update strategy value (#{queue_update_strategy})")

    if !queue_update_strategy.nil? && !queue_update_strategy.empty?
      # Act based on queue update strategy value
      case queue_update_strategy
      when "COMPUTE_FLEET_STOP"
        Chef::Log.info("Queue update strategy is (#{queue_update_strategy}), doing nothing")
      when "DRAIN", "TERMINATE"
        Chef::Log.info("Queue update strategy is (#{queue_update_strategy})")
        queues = get_queues_with_changes
        update_nodes_in_queue(queue_update_strategy, queues)
      else
        Chef::Log.info("Queue update strategy not managed, no-op")
      end
    end
  end
end

execute "generate_pcluster_slurm_configs" do
  command "#{node['cluster']['cookbook_virtualenv_path']}/bin/python #{node['cluster']['scripts_dir']}/slurm/pcluster_slurm_config_generator.py" \
          " --output-directory #{node['cluster']['slurm']['install_dir']}/etc/" \
          " --template-directory #{node['cluster']['scripts_dir']}/slurm/templates/" \
          " --input-file #{node['cluster']['cluster_config_path']}" \
          " --instance-types-data #{node['cluster']['instance_types_data_path']}" \
          " --compute-node-bootstrap-timeout #{node['cluster']['compute_node_bootstrap_timeout']}" \
          " #{nvidia_installed? ? '' : '--no-gpu'}"\
          " --realmemory-to-ec2memory-ratio #{node['cluster']['realmemory_to_ec2memory_ratio']}"
  not_if { ::File.exist?(node['cluster']['previous_cluster_config_path']) && !are_queues_updated? }
end

replace_or_add "update node replacement timeout" do
  path "/etc/parallelcluster/slurm_plugin/parallelcluster_clustermgtd.conf"
  pattern "node_replacement_timeout*"
  line "node_replacement_timeout = #{node['cluster']['compute_node_bootstrap_timeout']}"
  replace_only true
end

service 'slurmctld' do
  action :restart
  not_if { ::File.exist?(node['cluster']['previous_cluster_config_path']) && !are_queues_updated? }
end

chef_sleep '5'

execute 'reload config for running nodes' do
  command "#{node['cluster']['slurm']['install_dir']}/bin/scontrol reconfigure"
  retries 3
  retry_delay 5
  timeout 300
  not_if { ::File.exist?(node['cluster']['previous_cluster_config_path']) && !are_queues_updated? }
end

chef_sleep '15'

execute 'start clustermgtd' do
  command "#{node['cluster']['cookbook_virtualenv_path']}/bin/supervisorctl start clustermgtd"
  not_if { ::File.exist?(node['cluster']['previous_cluster_config_path']) && !are_queues_updated? }
end
