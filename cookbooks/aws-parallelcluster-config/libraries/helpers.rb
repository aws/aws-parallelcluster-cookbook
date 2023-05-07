# frozen_string_literal: true

# Copyright:: 2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

#
# Check if a service is installed in the instance and in the specific platform
#
def is_service_installed?(service, platform_families = node['platform_family'])
  if platform_family?(platform_families)
    # Add chkconfig for alinux2 and centos platform, because they do not generate systemd unit file automatically from init script
    # Ubuntu platform generate systemd unit file from init script automatically, if the service is not found by systemd the check will fail because chkconfig does not exist
    service_check = Mixlib::ShellOut.new("systemctl daemon-reload; systemctl list-unit-files --all | grep #{service} || chkconfig --list #{service}")
    service_check.run_command
    # convert return code in boolean
    service_check.exitstatus.to_i.zero?
  else
    # in case of different platform return false
    false
  end
end

# load shared storages data into node object
def load_shared_storages_mapping
  ruby_block "load shared storages mapping during cluster update" do
    block do
      require 'yaml'
      # regenerate the shared storages mapping file after update
      node.default['cluster']['shared_storages_mapping'] = YAML.safe_load(File.read(node['cluster']['previous_shared_storages_mapping_path']))
      node.default['cluster']['update_shared_storages_mapping'] = YAML.safe_load(File.read(node['cluster']['shared_storages_mapping_path']))
    end
  end
end
