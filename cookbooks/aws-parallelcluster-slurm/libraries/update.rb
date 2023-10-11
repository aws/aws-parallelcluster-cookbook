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
# rubocop:disable Style/SingleArgumentDig

# Helpers functions used by update recipe steps.
require 'chef/mixin/shell_out'
require 'net/http'
require 'timeout'

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

def config_parameter_changed?(param)
  # Compares previous cluster config with the current one for changes in a parameter
  # Parameters:
  # - `param`: An array representing the sequence of nested keys to the parameter to be checked
  require 'yaml'
  config = YAML.safe_load(File.read(node['cluster']['cluster_config_path']))
  previous_config = YAML.safe_load(File.read(node['cluster']['previous_cluster_config_path']))
  config.dig(*param) != previous_config.dig(*param)
end

def is_slurm_database_updated?
  config_parameter_changed?(%w(Scheduling SlurmSettings Database))
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

# Verify if MungeKeySecretArn in SlurmSettings section of cluster configuration has been updated
def is_custom_munge_key_updated?
  config_parameter_changed?(%w(Scheduling SlurmSettings MungeKeySecretArn))
end

def is_login_nodes_pool_name_updated?
  config_parameter_changed?(['LoginNodes', 'Pools', 0, 'Name'])
end

def is_login_nodes_removed?
  require 'yaml'
  config = YAML.safe_load(File.read(node['cluster']['cluster_config_path']))
  previous_config = YAML.safe_load(File.read(node['cluster']['previous_cluster_config_path']))
  previous_config.dig("LoginNodes") and !config.dig("LoginNodes")
end
