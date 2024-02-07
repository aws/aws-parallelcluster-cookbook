# frozen_string_literal: true

resource_name :fetch_config
provides :fetch_config
unified_mode true

property :update, [true, false],
         default: false

default_action :run

action :run do
  return if on_docker?
  Chef::Log.debug("Called fetch_config with update (#{new_resource.update})")

  sync_file = "#{node['cluster']['shared_dir']}/cluster-config-version"

  case node['cluster']['node_type']
  when 'HeadNode'
    if new_resource.update
      Chef::Log.info("Backing up old configuration from (#{node['cluster']['cluster_config_path']}) to (#{node['cluster']['previous_cluster_config_path']})")
      ::FileUtils.cp_r(node['cluster']['cluster_config_path'], node['cluster']['previous_cluster_config_path'], remove_destination: true)
      fetch_cluster_config(node['cluster']['cluster_config_path'])

      Chef::Log.info("Backing up old instance types data from (#{node['cluster']['instance_types_data_path']}) to (#{node['cluster']['previous_instance_types_data_path']})")
      ::FileUtils.cp_r(node['cluster']['instance_types_data_path'], node['cluster']['previous_instance_types_data_path'], remove_destination: true)

      fetch_change_set
      fetch_instance_type_data unless ::FileUtils.identical?(node['cluster']['previous_cluster_config_path'], node['cluster']['cluster_config_path'])
      Chef::Log.info("Backing up old shared storages data from (#{node['cluster']['shared_storages_mapping_path']}) to (#{node['cluster']['previous_shared_storages_mapping_path']})")
      ::FileUtils.cp_r(node['cluster']['shared_storages_mapping_path'], node['cluster']['previous_shared_storages_mapping_path'], remove_destination: true)
    else
      fetch_cluster_config(node['cluster']['cluster_config_path']) unless ::File.exist?(node['cluster']['cluster_config_path'])
      fetch_instance_type_data unless ::File.exist?(node['cluster']['instance_types_data_path'])
    end

    # ensure config is shared also with login nodes
    share_config_with_login_nodes

    # load cluster config into a node object
    load_cluster_config(node['cluster']['cluster_config_path'])

    # Write config version file to signal other cluster nodes that all configuration files within the shared folder
    # are aligned with the latest config version.
    write_config_version_file(sync_file)
  when 'ComputeFleet'
    if kitchen_test?
      fetch_cluster_config(node['cluster']['cluster_config_path']) unless ::File.exist?(node['cluster']['cluster_config_path'])
      write_config_version_file(sync_file)
    end

    if new_resource.update
      # Wait for the head node to write the config version file, which is the signal that
      # all configuration files within the shared folder are aligned with the latest config version.
      # This is required only on update because on create it is guaranteed that this recipe is executed on compute node
      # only after it has completed on head node.
      wait_cluster_config_file(sync_file)

      # TODO: If the shared storage mapping files contain cluster-wide information and not node-specific data,
      #  then make the head node write the shared storage mapping files in the shared folder
      #  and let compute node consume them.
      Chef::Log.info("Backing up old shared storages data from (#{node['cluster']['shared_storages_mapping_path']}) to (#{node['cluster']['previous_shared_storages_mapping_path']})")
      ::FileUtils.cp_r(node['cluster']['shared_storages_mapping_path'], node['cluster']['previous_shared_storages_mapping_path'], remove_destination: true)
    else
      raise "Cluster config not found in #{node['cluster']['cluster_config_path']}" unless ::File.exist?(node['cluster']['cluster_config_path'])
    end

    # load cluster config into a node object
    load_cluster_config(node['cluster']['cluster_config_path'])
  when 'LoginNode'
    raise "Cluster config not found in #{node['cluster']['login_cluster_config_path']}" unless ::File.exist?(node['cluster']['login_cluster_config_path'])
    # load cluster config into a node object
    load_cluster_config(node['cluster']['login_cluster_config_path'])
  else
    raise "node_type must be HeadNode, LoginNode or ComputeFleet"
  end
end

action_class do # rubocop:disable Metrics/BlockLength
  def execute_command(label, run_command)
    execute label do
      command run_command
      retries 3
      retry_delay 5
      timeout 300
    end
  end

  def fetch_s3_object(command_label, key, output, version_id = nil)
    fetch_s3_object_command = "#{cookbook_virtualenv_path}/bin/aws s3api get-object" \
                         " --bucket #{node['cluster']['cluster_s3_bucket']}" \
                         " --key #{key}" \
                         " --region #{node['cluster']['region']}" \
                         " #{output}"
    fetch_s3_object_command += " --version-id #{version_id}" unless version_id.nil?
    execute_command(command_label, fetch_s3_object_command)
  end

  def fetch_cluster_config(config_path)
    if kitchen_test? && !node['interact_with_s3']
      remote_file "copy fake cluster config" do
        path node['cluster']['cluster_config_path']
        source "file://#{kitchen_cluster_config_path}"
      end
    else
      # Copy cluster config file from S3 URI
      version_id = node['cluster']['cluster_config_version'] unless node['cluster']['cluster_config_version'].nil?
      fetch_s3_object("copy_cluster_config_from_s3", node['cluster']['cluster_config_s3_key'], config_path, version_id)
    end
  end

  def fetch_change_set
    # Copy change set file from S3 URI
    fetch_s3_object("copy_change_set_from_s3", node['cluster']['change_set_s3_key'], node['cluster']['change_set_path'])
  end

  def share_config_with_login_nodes
    # Share cluster config with login nodes (only if they exist)
    Chef::Log.info("Sharing cluster config with login nodes")
    ::FileUtils.cp_r(node['cluster']['cluster_config_path'],
                     node['cluster']['login_cluster_config_path'],
                     remove_destination: true) unless !::File.exist?(node['cluster']['cluster_config_path'])
    ::FileUtils.cp_r(node['cluster']['previous_cluster_config_path'],
                     node['cluster']['login_previous_cluster_config_path'],
                     remove_destination: true) unless !::File.exist?(node['cluster']['previous_cluster_config_path'])
  end

  def fetch_instance_type_data
    if kitchen_test? && !node['interact_with_s3']
      remote_file "copy fake instance type data" do
        path node['cluster']['instance_types_data_path']
        source "file://#{kitchen_instance_types_data_path}"
      end
    else
      # Copy instance type infos file from S3 URI
      instance_version_id = node['cluster']['instance_types_data_version'] unless node['cluster']['instance_types_data_version'].nil?
      fetch_s3_object("copy_instance_type_data_from_s3", node['cluster']['instance_types_data_s3_key'], node['cluster']['instance_types_data_path'], instance_version_id)
    end
  end

  def write_config_version_file(path)
    # Write the cluster config version into the specified file.
    # This file is used as a synchronization point between the head node and the other cluster nodes.
    # In particular, the head node uses this file to signal to other cluster nodes that all files
    # in the shared folder related to the cluster config have been updated with the current config version.
    file path do
      content node['cluster']['cluster_config_version']
      mode '0644'
      owner 'root'
      group 'root'
    end
  end

  def wait_cluster_config_file(path)
    # Wait for the config version file to contain the current cluster config version.
    bash "Wait cluster config files to be updated by the head node" do
      code "[[ \"$(cat #{path})\" == \"#{node['cluster']['cluster_config_version']}\" ]] || exit 1"
      retries 30
      retry_delay 10
      timeout 5
    end
  end
end
