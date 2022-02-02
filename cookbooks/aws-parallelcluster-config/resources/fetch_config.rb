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
  def fetch_cluster_config(config_path)
    # Copy cluster config file from S3 URI
    fetch_config_command = "#{node['cluster']['cookbook_virtualenv_path']}/bin/aws s3api get-object" \
                         " --bucket #{node['cluster']['cluster_s3_bucket']}" \
                         " --key #{node['cluster']['cluster_config_s3_key']}" \
                         " --region #{node['cluster']['region']}" \
                         " #{config_path}"
    fetch_config_command += " --version-id #{node['cluster']['cluster_config_version']}" unless node['cluster']['cluster_config_version'].nil?
    execute "copy_cluster_config_from_s3" do
      command fetch_config_command
      retries 3
      retry_delay 5
    end
  end

  def fetch_instance_type_data
    # Copy instance type infos file from S3 URI
    fetch_config_command = "#{node['cluster']['cookbook_virtualenv_path']}/bin/aws s3api get-object" \
                           " --bucket #{node['cluster']['cluster_s3_bucket']}" \
                           " --key #{node['cluster']['instance_types_data_s3_key']}" \
                           " --region #{node['cluster']['region']}" \
                           " #{node['cluster']['instance_types_data_path']}"
    execute "copy_instance_type_data_from_s3" do
      command fetch_config_command
      retries 3
      retry_delay 5
    end
  end
end
