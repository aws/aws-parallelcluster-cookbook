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
  return if on_docker? || imex_installed? || aws_region.start_with?("us-iso")

  directory node['cluster']['nvidia']['imex']['shared_dir']

  action_install_imex
  # Save Imex version in Node Attributes for InSpec Tests
  node.default['cluster']['nvidia']['imex']['version'] = nvidia_imex_full_version
  node.default['cluster']['nvidia']['imex']['package'] = nvidia_imex_package
  node_attributes 'dump node attributes'
end

action :configure do
  return unless imex_installed? && node['cluster']['node_type'] == "ComputeFleet"
  # Start nvidia-imex on p6e-gb200 and only on ComputeFleet
  if get_nvswitch_count(get_device_ids['gb200']) > 1
    # For each Compute Resource, we generate a unique NVIDIA IMEX configuration file,
    # if one doesn't already exist in a common, shared location.
    template nvidia_imex_nodes_conf_file do
      source 'nvidia-imex/nvidia-imex-nodes.erb'
      owner 'root'
      group 'root'
      mode '0755'
      action :create
      not_if { file_exists_and_cluster_update?(nvidia_imex_nodes_conf_file) }
    end

    template nvidia_imex_main_conf_file do
      source 'nvidia-imex/nvidia-imex-config.erb'
      owner 'root'
      group 'root'
      mode '0755'
      action :create
      not_if { file_exists_and_cluster_update?(nvidia_imex_main_conf_file) }
      variables(imex_nodes_config_file_path: nvidia_imex_nodes_conf_file)
    end

    template "/etc/systemd/system/#{nvidia_imex_service}.service" do
      source 'nvidia-imex/nvidia-imex.service.erb'
      owner 'root'
      group 'root'
      mode '0644'
      action :create
      variables(imex_main_config_file_path: nvidia_imex_main_conf_file)
    end

    service nvidia_imex_service do
      action %i(enable start)
      supports status: true
    end
  end
end

def nvidia_imex_package
  "#{nvidia_imex_service}-#{nvidia_driver_major_version}"
end

def nvidia_driver_major_version
  node['cluster']['nvidia']['driver_version'].split('.')[0]
end

def nvidia_imex_service
  'nvidia-imex'
end

def nvidia_imex_full_version
  "#{node['cluster']['nvidia']['driver_version']}-1"
end

def imex_installed?
  ::File.exist?("/usr/bin/#{nvidia_imex_service}") || ::File.exist?("/usr/bin/#{nvidia_imex_service}-ctl")
end

def nvidia_enabled_or_installed?
  nvidia_enabled? || nvidia_installed?
end

def file_exists_and_cluster_update?(file_path)
  ::File.exist?(file_path) && !are_queues_updated?
end

def nvidia_imex_main_conf_file
  "#{node['cluster']['nvidia']['imex']['shared_dir']}/config_#{node['cluster']['launch_template_id']}.cfg"
end

def nvidia_imex_nodes_conf_file
  "#{node['cluster']['nvidia']['imex']['shared_dir']}/nodes_config_#{node['cluster']['launch_template_id']}.cfg"
end
