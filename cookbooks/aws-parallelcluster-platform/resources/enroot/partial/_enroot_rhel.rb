# frozen_string_literal: true
#
# Copyright:: 2013-2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

action :install_package do
  return unless nvidia_enabled? || nvidia_installed?

  robust_package 'install enroot prerequisites' do
    packages prerequisites
  end

  bash "Install enroot" do
    user 'root'
    cwd node['cluster']['sources_dir']
    code <<-ENROOT_INSTALL
      set -e
      yum install -y #{enroot_url}
      yum install -y #{enroot_caps_url}
    ENROOT_INSTALL
    retries 3
    retry_delay 5
  end
end

def enroot_url
  "#{node['cluster']['enroot']['base_url']}/enroot-#{package_version}-1.el8.#{arch_suffix}.rpm"
end

def enroot_caps_url
  base_url = node['cluster']['enroot']['caps_base_url']
  caps_name = default_artifacts_url?(base_url) ? 'enroot-caps' : 'enroot+caps'
  "#{base_url}/#{caps_name}-#{package_version}-1.el8.#{arch_suffix}.rpm"
end

def arch_suffix
  arm_instance? ? 'aarch64' : 'x86_64'
end
