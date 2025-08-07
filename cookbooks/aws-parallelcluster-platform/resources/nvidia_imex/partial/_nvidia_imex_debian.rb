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

action :install_imex do
  remote_file "#{node['cluster']['sources_dir']}/#{nvidia_imex_package}-#{nvidia_imex_full_version}.deb" do
    source "#{nvidia_imex_url}"
    mode '0644'
    retries 3
    retry_delay 5
    action :create_if_missing
  end

  bash "Install nvidia-imex" do
    user 'root'
    cwd node['cluster']['sources_dir']
    code <<-NVIDIA_IMEX
    set -e
    dpkg -i #{nvidia_imex_package}-#{nvidia_imex_full_version}.deb && apt-mark hold #{nvidia_imex_package}
    NVIDIA_IMEX
    retries 3
    retry_delay 5
  end
end

def nvidia_imex_url
  "#{node['cluster']['artifacts_s3_url']}/dependencies/nvidia_imex/#{platform}/#{nvidia_imex_package}_#{nvidia_imex_full_version}_#{arch_suffix}.deb"
end

def arch_suffix
  arm_instance? ? 'arm64' : 'amd64'
end
