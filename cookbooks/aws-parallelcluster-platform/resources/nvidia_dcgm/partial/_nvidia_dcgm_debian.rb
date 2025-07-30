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
  packages_urls_list = if package_version.start_with?("3.")
                         [dcgm_package]
                       else
                         [dcgm4_core_package, dcgm4_package]
                       end
  packages_urls_list.each do |package|
    remote_file "#{node['cluster']['sources_dir']}/#{package}-#{package_version}.deb" do
      source "#{node['cluster']['artifacts_s3_url']}/dependencies/nvidia_dcgm/#{platform}/#{package}_#{package_version}_#{arch_suffix}.deb"
      mode '0644'
      retries 3
      retry_delay 5
      action :create_if_missing
    end

    bash "Install #{package}" do
      user 'root'
      cwd node['cluster']['sources_dir']
      code <<-DCGM_INSTALL
      set -e
      dpkg -i #{package}-#{package_version}.deb
      DCGM_INSTALL
      retries 3
      retry_delay 5
    end
  end
end

def dcgm_package
  'datacenter-gpu-manager'
end

def dcgm4_package
  "#{dcgm_package}-4-cuda12"
end

def dcgm4_core_package
  "#{dcgm_package}-4-core"
end

def arch_suffix
  arm_instance? ? 'arm64' : 'amd64'
end

def package_version
  node['cluster']['nvidia']['dcgm_version']
end
