# frozen_string_literal: true

resource_name :fetch_config
provides :fetch_config
unified_mode true

property :update, [true, false],
         default: false

default_action :run

action :run do
  Chef::Log.debug("Called fetch_config with update (#{new_resource.update})")
  unless virtualized?
    if new_resource.update
      Chef::Log.info("Backing up old configuration from (#{node['cluster']['cluster_config_path']}) to (#{node['cluster']['previous_cluster_config_path']})")
      ::FileUtils.cp_r(node['cluster']['cluster_config_path'], node['cluster']['previous_cluster_config_path'], remove_destination: true)
      fetch_cluster_config(node['cluster']['cluster_config_path'])
      fetch_change_set if are_queues_updated?
      fetch_instance_type_data unless ::FileUtils.identical?(node['cluster']['previous_cluster_config_path'], node['cluster']['cluster_config_path'])
    else
      fetch_cluster_config(node['cluster']['cluster_config_path']) unless ::File.exist?(node['cluster']['cluster_config_path'])
      fetch_instance_type_data unless ::File.exist?(node['cluster']['instance_types_data_path'])
    end

    # load cluster config into node object
    load_cluster_config
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
    fetch_s3_object_command = "#{node['cluster']['cookbook_virtualenv_path']}/bin/aws s3api get-object" \
                         " --bucket #{node['cluster']['cluster_s3_bucket']}" \
                         " --key #{key}" \
                         " --region #{node['cluster']['region']}" \
                         " #{output}"
    fetch_s3_object_command += " --version-id #{version_id}" unless version_id.nil?
    execute_command(command_label, fetch_s3_object_command)
  end

  def fetch_cluster_config(config_path)
    # Copy cluster config file from S3 URI
    version_id = node['cluster']['cluster_config_version'] unless node['cluster']['cluster_config_version'].nil?
    fetch_s3_object("copy_cluster_config_from_s3", node['cluster']['cluster_config_s3_key'], config_path, version_id)
  end

  def fetch_change_set
    # Copy change set file from S3 URI
    fetch_s3_object("copy_change_set_from_s3", node['cluster']['change_set_s3_key'], node['cluster']['change_set_path'])
  end

  def fetch_instance_type_data
    # Copy instance type infos file from S3 URI
    fetch_s3_object("copy_instance_type_data_from_s3", node['cluster']['instance_types_data_s3_key'], node['cluster']['instance_types_data_path'])
  end
end
