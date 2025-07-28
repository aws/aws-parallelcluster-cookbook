# frozen_string_literal: true
#
# Copyright:: 2013-2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
  return if on_docker? || imex_installed || aws_region.start_with?("us-iso")

  # Add NVIDIA repo for nvidia-imex
  nvidia_repo 'add nvidia repository' do
    action :add
  end

  directory "#{node['cluster']['shared_dir']}/nvidia-imex"

  template "#{node['cluster']['shared_dir']}/nvidia-imex/config.cfg" do
    source 'nvidia-imex/nvidia-imex-config.erb'
    owner 'root'
    group 'root'
    mode '0755'
  end

  template "#{node['cluster']['shared_dir']}/nvidia-imex/nodes_config.cfg" do
    source 'nvidia-imex/nvidia-imex-nodes.erb'
    owner 'root'
    group 'root'
    mode '0755'
  end

  template "/etc/systemd/system/nvidia-imex.service" do
    source 'nvidia-imex/nvidia-imex.service.erb'
    owner 'root'
    group 'root'
    mode '0644'
    action :create
  end

  package "nvidia-imex-#{_nvidia_imex_version}" do
    retries 3
    retry_delay 5
    flush_cache({ before: true })
    # version _nvidia_imex_version
  end
end

action :configure do
  return unless imex_installed
  # Start nvidia-imex on p6e-gb200
  if get_nvswitch_count(get_device_ids['gb200']) > 1
    service 'nvidia-imex' do
      action %i(start enable)
      supports status: true
    end unless on_docker?
  end
end

def imex_installed
  ::File.exist?('/usr/bin/nvidia-imex') || ::File.exist?('/usr/bin/nvidia-imex-ctl')
end

def nvidia_enabled_or_installed?
  nvidia_enabled? || nvidia_installed?
end
