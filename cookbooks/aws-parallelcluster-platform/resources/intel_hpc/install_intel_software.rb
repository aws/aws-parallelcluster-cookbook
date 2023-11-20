# frozen_string_literal: true

# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

provides :install_intel_software

unified_mode true

property :intel_offline_installer_dir, String, required: true
property :software_name, String, required: true
property :software_url, String, required: true

default_action :install

action :install do
  remote_file "#{new_resource.intel_offline_installer_dir}/#{new_resource.software_name}" do
    source new_resource.software_url
    mode '0744'
    retries 3
    retry_delay 5
    action :create_if_missing
  end
  bash "install Intel #{new_resource.software_name}" do
    cwd new_resource.intel_offline_installer_dir
    code <<-INTEL
    set -e
    sh #{new_resource.software_name} -a -s --eula accept
    rm -f #{new_resource.software_name}
    INTEL
  end
end
