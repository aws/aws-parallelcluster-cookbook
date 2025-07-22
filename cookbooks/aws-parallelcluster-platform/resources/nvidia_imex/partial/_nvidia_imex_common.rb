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

  package 'nvidia-imex' do
    retries 3
    retry_delay 5
    version node['cluster']['nvidia']['driver_version']
  end
end

def imex_installed
  ::File.exist?('/usr/bin/nvidia-imex') || ::File.exist?('/usr/bin/nvidia-imex-ctl')
end

def nvidia_enabled_or_installed?
  nvidia_enabled? || nvidia_installed?
end
