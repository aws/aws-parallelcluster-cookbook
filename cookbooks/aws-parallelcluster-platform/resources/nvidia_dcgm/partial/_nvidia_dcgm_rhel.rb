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
  if package_version.start_with?("3.")
    packages_urls_list = [dcgm_package]
    package_url_separator = "-"
  else
    packages_urls_list = [dcgm4_core_package, dcgm4_package]
    package_url_separator = "."
  end
  packages_urls_list.each do |package|
    remote_file "#{node['cluster']['sources_dir']}/#{package}-#{package_version}.rpm" do
      source "#{node['cluster']['artifacts_s3_url']}/dependencies/nvidia_dcgm/#{platform}/#{package}-#{package_version}#{package_url_separator}#{arch_suffix}.rpm"
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
      yum install -y #{package}-#{package_version}.rpm
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
  arm_instance? ? 'aarch64' : 'x86_64'
end

def package_version
  node['cluster']['nvidia']['dcgm_version']
end
