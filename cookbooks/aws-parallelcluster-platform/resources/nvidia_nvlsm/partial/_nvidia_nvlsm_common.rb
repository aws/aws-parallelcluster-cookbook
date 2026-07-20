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
  return unless nvlsm_installation_enabled?

  action_install_nvlsm_dependencies

  package nvidia_nvlsm_package do
    retries 3
    retry_delay 5
  end

  action_lock_package_version
end

action :install_nvlsm_dependencies do
  bash "Install nvlsm dependencies" do
    user 'root'
    code <<-CODE
    set -ex
    #{nvidia_nvlsm_install_dependencies_commands}
    CODE
    retries 3
    retry_delay 5
  end

  # Make sure kernel module for Infiniband is loaded at instance boot time
  cookbook_file 'infiniband.conf' do
    source 'infiniband/infiniband.conf'
    path '/etc/modules-load.d/parallelcluster-infiniband.conf'
    owner 'root'
    group 'root'
    mode '0644'
  end
end

def nvidia_nvlsm_package
  "nvlsm"
end

def nvidia_nvlsm_install_dependencies_commands
  # OS dependent
end

def nvlsm_installation_enabled?
  if on_docker? ||
     node['cluster']['nvidia']['nvlsm']['enabled'] == false ||
     !nvidia_enabled? ||
     nvlsm_installed?
    false
  else
    true
  end
end

def nvlsm_installed?
  ::File.exist?("/opt/nvidia/nvlsm/sbin/nvlsm")
end
