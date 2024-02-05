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
  command "#{cookbook_virtualenv_path}/bin/supervisorctl stop clustermgtd"
  not_if { ::File.exist?(node['cluster']['previous_cluster_config_path']) && !are_queues_updated? && !are_bulk_custom_slurm_settings_updated? }
end

ruby_block "update_shared_storages" do
  block do
    run_context.include_recipe 'aws-parallelcluster-environment::update_shared_storages'
  end
  only_if { are_mount_or_unmount_required? }
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

  def get_all_queues(config)
    # Get all queue names from the cluster config
    slurm_queues = config.dig("Scheduling", "SlurmQueues")
    queues_name = Set.new
    slurm_queues.each do |queue|
      queues_name.add(queue["Name"])
    end
    queues_name
  end

  def get_queues_with_changes(config)
    # Load change set and find queue with changes
    queues = Set.new
    change_set = JSON.load_file("#{node['cluster']['shared_dir']}/change-set.json")
    Chef::Log.debug("Loaded change set (#{change_set})")
    if are_mount_or_unmount_required? # Changes with SHARED_STORAGE_UPDATE_POLICY require all queues to update
      queues = get_all_queues(config)
      Chef::Log.info("All queues will be updated in order to update shared storages")
    else
      change_set["changeSet"].each do |change|
        next unless change["updatePolicy"] == "QUEUE_UPDATE_STRATEGY"
        queue = change["parameter"][/Scheduling\.SlurmQueues\[([^\]]*)\]/, 1]
        Chef::Log.info("Adding queue (#{queue}) to list of queue to be updated")
        queues.add(queue)
      end
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
        queues = get_queues_with_changes(config)
        update_nodes_in_queue(queue_update_strategy, queues)
      else
        Chef::Log.info("Queue update strategy not managed, no-op")
      end
    end
  end
end

execute "generate_pcluster_slurm_configs" do
  command "#{cookbook_virtualenv_path}/bin/python #{node['cluster']['scripts_dir']}/slurm/pcluster_slurm_config_generator.py" \
          " --output-directory #{node['cluster']['slurm']['install_dir']}/etc/" \
          " --template-directory #{node['cluster']['scripts_dir']}/slurm/templates/" \
          " --input-file #{node['cluster']['cluster_config_path']}" \
          " --instance-types-data #{node['cluster']['instance_types_data_path']}" \
          " --compute-node-bootstrap-timeout #{node['cluster']['compute_node_bootstrap_timeout']}" \
          " #{nvidia_installed? ? '' : '--no-gpu'}"\
          " --realmemory-to-ec2memory-ratio #{node['cluster']['realmemory_to_ec2memory_ratio']}"\
          " --slurmdbd-user #{node['cluster']['slurm']['user']}"\
          " --cluster-name #{node['cluster']['stack_name']}"
  not_if { ::File.exist?(node['cluster']['previous_cluster_config_path']) && !are_queues_updated? }
end

# Generate custom Slurm settings include files
execute "generate_pcluster_custom_slurm_settings_include_files" do
  command "#{cookbook_virtualenv_path}/bin/python #{node['cluster']['scripts_dir']}/slurm/pcluster_custom_slurm_settings_include_file_generator.py" \
            " --output-directory #{node['cluster']['slurm']['install_dir']}/etc/"\
            " --input-file #{node['cluster']['cluster_config_path']}"
  not_if { ::File.exist?(node['cluster']['previous_cluster_config_path']) && !are_bulk_custom_slurm_settings_updated? }
end

# If defined in the config, retrieve a remote Custom Slurm Settings file and overrides the existing one
ruby_block "Override Custom Slurm Settings with remote file" do
  block do
    run_context.include_recipe 'aws-parallelcluster-slurm::retrieve_remote_custom_settings_file'
  end
  not_if { node['cluster']['config'].dig(:Scheduling, :SlurmSettings, :CustomSlurmSettingsIncludeFile).nil? }
end

execute "generate_pcluster_fleet_config" do
  command "#{cookbook_virtualenv_path}/bin/python #{node['cluster']['scripts_dir']}/slurm/pcluster_fleet_config_generator.py"\
          " --output-file #{node['cluster']['slurm']['fleet_config_path']}"\
          " --input-file #{node['cluster']['cluster_config_path']}"
  not_if { ::File.exist?(node['cluster']['slurm']['fleet_config_path']) && !are_queues_updated? }
end

replace_or_add "update node replacement timeout" do
  path "#{node['cluster']['etc_dir']}/slurm_plugin/parallelcluster_clustermgtd.conf"
  pattern "node_replacement_timeout*"
  line "node_replacement_timeout = #{node['cluster']['compute_node_bootstrap_timeout']}"
  replace_only true
end

ruby_block "Update Slurm Accounting" do
  block do
    if node['cluster']['config'].dig(:Scheduling, :SlurmSettings, :Database).nil?
      run_context.include_recipe "aws-parallelcluster-slurm::clear_slurm_accounting"
    else
      run_context.include_recipe "aws-parallelcluster-slurm::config_slurm_accounting"
    end
  end
  only_if { ::File.exist?(node['cluster']['previous_cluster_config_path']) && is_slurm_database_updated? }
end unless on_docker?

# Cover the following two scenarios:
# - a cluster without login nodes is updated to have login nodes;
# - a cluster with login nodes is updated to use another pool name.
if ::File.exist?(node['cluster']['previous_cluster_config_path']) && is_login_nodes_pool_name_updated?
  include_recipe 'aws-parallelcluster-slurm::config_check_login_stopped_script'
end

file "#{node['cluster']['scripts_dir']}/slurm/check_login_nodes_stopped.sh" do
  action :delete
  only_if { ::File.exist?(node['cluster']['previous_cluster_config_path']) && is_login_nodes_removed? }
end

# Update munge key rotation script to update secret arn
template "#{node['cluster']['scripts_dir']}/slurm/update_munge_key.sh" do
  source 'slurm/head_node/update_munge_key.sh.erb'
  owner 'root'
  group 'root'
  mode '0700'
  variables(
    munge_key_secret_arn: lazy { node['cluster']['config'].dig(:Scheduling, :SlurmSettings, :MungeKeySecretArn) },
    region: node['cluster']['region'],
    munge_user: node['cluster']['munge']['user'],
    munge_group: node['cluster']['munge']['group'],
    shared_directory_compute: node['cluster']['shared_dir'],
    shared_directory_login: node['cluster']['shared_dir_login_nodes']
  )
  only_if { ::File.exist?(node['cluster']['previous_cluster_config_path']) && is_custom_munge_key_updated? }
end

update_munge_head_node

# The previous execute "generate_pcluster_slurm_configs" block resource may have overridden the slurmdbd password in
# slurm_parallelcluster_slurmdbd.conf with a default value, so if it has run and Slurm accounting
# is enabled we must pull the database password from Secrets Manager once again.
execute "update Slurm database password" do
  user 'root'
  group 'root'
  command "#{node['cluster']['scripts_dir']}/slurm/update_slurm_database_password.sh"
  # This horrible only_if guard is needed to cover all cases that trigger "generate_pcluster_slurm_settings", in the case Slurm accounting is being used
  only_if { !(::File.exist?(node['cluster']['previous_cluster_config_path']) && !are_queues_updated?) && !node['cluster']['config'].dig(:Scheduling, :SlurmSettings, :Database).nil? }
end

service 'slurmctld' do
  action :restart
  not_if { ::File.exist?(node['cluster']['previous_cluster_config_path']) && !are_queues_updated? && !are_bulk_custom_slurm_settings_updated? }
end

chef_sleep '5'

# The slurmctld service does not return an error code to `systemctl start slurmctld`, so
# we must explicitly check the status of the service to capture failures
execute "check slurmctld status" do
  command "systemctl is-active --quiet slurmctld.service"
  retries 5
  retry_delay 2
end

execute 'reload config for running nodes' do
  command "#{node['cluster']['slurm']['install_dir']}/bin/scontrol reconfigure"
  retries 3
  retry_delay 5
  timeout 300
  not_if { ::File.exist?(node['cluster']['previous_cluster_config_path']) && !are_queues_updated? && !are_bulk_custom_slurm_settings_updated? }
end

chef_sleep '15'

execute 'start clustermgtd' do
  command "#{cookbook_virtualenv_path}/bin/supervisorctl start clustermgtd"
  not_if { ::File.exist?(node['cluster']['previous_cluster_config_path']) && !are_queues_updated? && !are_bulk_custom_slurm_settings_updated? }
end

# The updated cfnconfig will be used by post update custom scripts
template "#{node['cluster']['etc_dir']}/cfnconfig" do
  source 'init/cfnconfig.erb'
  cookbook 'aws-parallelcluster-environment'
  mode '0644'
end

wait_cluster_ready
