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
default_action :install

action :install do
  return unless nvidia_enabled_or_installed?
  return if on_docker? || imex_installed?

  package nvidia_imex_package do
    retries 3
    retry_delay 5
  end

  action_lock_package_version

  # Create Imex configuration files
  action_create_configuration_files
  # Save Imex package in Node Attributes for InSpec Tests
  node.default['cluster']['nvidia']['imex']['package'] = nvidia_imex_package
  node_attributes 'dump node attributes'
end

action :create_configuration_files do
  # We create or update IMEX configuration files if ParallelCluster is installing IMEX
  template nvidia_imex_nodes_conf_file do
    source 'nvidia-imex/nvidia-imex-nodes.erb'
    owner 'root'
    group 'root'
    mode '0755'
    action :create
  end

  template nvidia_imex_main_conf_file do
    source 'nvidia-imex/nvidia-imex-config.erb'
    owner 'root'
    group 'root'
    mode '0755'
    action :create
    variables(imex_nodes_config_file_path: nvidia_imex_nodes_conf_file)
  end

  # We keep nvidia-imex.service file in this location to give precedence to pcluster configured service file.
  template "/etc/systemd/system/#{nvidia_imex_service}.service" do
    source 'nvidia-imex/nvidia-imex.service.erb'
    owner 'root'
    group 'root'
    mode '0644'
    action :create
    variables(imex_main_config_file_path: nvidia_imex_main_conf_file)
  end
end

action :configure do
  return unless imex_installed? && node['cluster']['node_type'] == "ComputeFleet"
  # Start nvidia-imex on p6e-gb200 and only on ComputeFleet
  if is_gb200_node? || enable_force_configuration?
    # Create the file if this is missing otherwise Imex service will not start
    template nvidia_imex_nodes_conf_file do
      source 'nvidia-imex/nvidia-imex-nodes.erb'
      owner 'root'
      group 'root'
      mode '0755'
      action :create_if_missing
    end

    service nvidia_imex_service do
      action %i(enable start)
      supports status: true
    end
  end
end

def nvidia_imex_package
  "#{nvidia_imex_service}"
end

def nvidia_imex_service
  'nvidia-imex'
end

def imex_installed?
  ::File.exist?("/usr/bin/#{nvidia_imex_service}") || ::File.exist?("/usr/bin/#{nvidia_imex_service}-ctl")
end

# Install IMEX when NVIDIA is enabled or already installed.
def nvidia_enabled_or_installed?
  nvidia_enabled? || nvidia_installed?
end

def nvidia_imex_main_conf_file
  "/etc/nvidia-imex/config.cfg"
end

def nvidia_imex_nodes_conf_file
  "/etc/nvidia-imex/nodes_config.cfg"
end

def enable_force_configuration?
  ['true', 'yes', true].include?(node['cluster']['nvidia']['imex']['force_configuration'])
end
