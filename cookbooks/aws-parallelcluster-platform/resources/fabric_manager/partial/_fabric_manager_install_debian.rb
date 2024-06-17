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
  # For ubuntu, CINC17 apt-package resources need full versions for `version`
  remote_file "#{node['cluster']['sources_dir']}/#{fabric_manager_package}-#{fabric_manager_version}.deb" do
    source "#{fabric_manager_url}"
    mode '0644'
    retries 3
    retry_delay 5
    action :create_if_missing
  end

  bash "install_fabricmanager_for_ubuntu" do
    user 'root'
    cwd node['cluster']['sources_dir']
    code <<-FABRIC_MANAGER
    set -e
    dpkg -i #{fabric_manager_package}-#{fabric_manager_version}.deb && apt-mark hold #{fabric_manager_package}
    FABRIC_MANAGER
    retries 3
    retry_delay 5
  end
end

def arch_suffix
  arm_instance? ? 'arm64' : 'amd64'
end

def fabric_manager_url
  "#{node['cluster']['artifacts_s3_url']}/dependencies/nvidia_fabric/#{platform}/#{fabric_manager_package}_#{fabric_manager_version}-1_#{arch_suffix}.deb"
end
