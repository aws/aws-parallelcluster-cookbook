# frozen_string_literal: true

# Copyright:: 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

require 'chef/mixin/shell_out'
require 'net/http'
require 'timeout'

def ignore_failure(lookup)
  resource = resources(lookup)
  if resource.nil?
    Chef::Log.warn("Can't find resource to ignore: #{lookup}")
  else
    Chef::Log.info("Ignore failure for resource: #{lookup}")
    resource.ignore_failure(true)
  end
end

#
# TODO use os_type resource, action :validate
#
#
# Check if OS type specified by the user is the same as the OS identified by Ohai
#
def validate_os_type
  case node['platform']
  when 'ubuntu'
    current_os = "ubuntu#{node['platform_version'].tr('.', '')}"
    raise_os_not_match(current_os, node['cluster']['base_os']) if node['cluster']['base_os'] != current_os
  when 'amazon'
    current_os = "alinux#{node['platform_version'].to_i}"
    raise_os_not_match(current_os, node['cluster']['base_os']) if node['cluster']['base_os'] != current_os
  when 'centos'
    current_os = "centos#{node['platform_version'].to_i}"
    raise_os_not_match(current_os, node['cluster']['base_os']) if node['cluster']['base_os'] != current_os
  when 'redhat'
    current_os = "rhel#{node['platform_version'].to_i}"
    raise_os_not_match(current_os, node['cluster']['base_os']) if node['cluster']['base_os'] != current_os
  end
end

#
# Raise error if OS types do not match
#
def raise_os_not_match(current_os, specified_os)
  raise "The custom AMI you have provided uses the #{current_os} OS. " \
        "However, the base_os specified in your config file is #{specified_os}. " \
        "Please either use an AMI with the #{specified_os} OS or update the base_os " \
        "setting in your configuration file to #{current_os}."
end

def kernel_release
  ENV['KERNEL_RELEASE'] || default['cluster']['kernel_release']
end

def run_command(command)
  Mixlib::ShellOut.new(command).run_command.stdout.strip
end

# Verify if Scheduling section of cluster configuration and compute node bootstrap_timeout have been updated
def are_queues_updated?
  require 'yaml'
  config = YAML.safe_load(File.read(node['cluster']['cluster_config_path']))
  previous_config = YAML.safe_load(File.read(node['cluster']['previous_cluster_config_path']))
  config["Scheduling"] != previous_config["Scheduling"] or is_compute_node_bootstrap_timeout_updated?(previous_config, config)
end

# Verify if CustomSlurmSettings has been updated in the config
def are_bulk_custom_slurm_settings_updated?
  require 'yaml'
  config = YAML.safe_load(File.read(node['cluster']['cluster_config_path']))
  previous_config = YAML.safe_load(File.read(node['cluster']['previous_cluster_config_path']))
  config["Scheduling"]["SlurmSettings"]["CustomSlurmSettings"] != previous_config["Scheduling"]["SlurmSettings"]["CustomSlurmSettings"]
end

def are_mount_or_unmount_required?
  require 'json'
  change_set = JSON.load_file("#{node['cluster']['shared_dir']}/change-set.json")
  change_set["changeSet"].each do |change|
    next unless change["updatePolicy"] == "SHARED_STORAGE_UPDATE_POLICY"

    return true
  end
  Chef::Log.info("No shared storages operation required.")
  false
end

def evaluate_compute_bootstrap_timeout(config)
  config.dig("DevSettings", "Timeouts", "ComputeNodeBootstrapTimeout") or 1800
end

def is_compute_node_bootstrap_timeout_updated?(previous_config, config)
  evaluate_compute_bootstrap_timeout(previous_config) != evaluate_compute_bootstrap_timeout(config)
end

def raise_command_error(command, cmd)
  Chef::Log.error("Error while executing command (#{command})")
  raise "#{cmd.stderr.strip}"
end

def execute_command(command, user = "root", timeout = 300, raise_on_error = true)
  cmd = Mixlib::ShellOut.new(command, user: user, timeout: timeout)
  cmd.run_command
  raise_command_error(command, cmd) if raise_on_error && cmd.error?
  cmd.stdout.strip
end

def is_slurm_database_updated?
  require 'yaml'
  config = YAML.safe_load(File.read(node['cluster']['cluster_config_path']))
  previous_config = YAML.safe_load(File.read(node['cluster']['previous_cluster_config_path']))
  config["Scheduling"]["SlurmSettings"]["Database"] != previous_config["Scheduling"]["SlurmSettings"]["Database"]
end
