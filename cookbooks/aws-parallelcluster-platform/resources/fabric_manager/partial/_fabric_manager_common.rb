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

unified_mode true
default_action :setup

property :nvidia_enabled, [true, false, nil]
property :nvidia_driver_version, String

action :setup do
  return unless _fabric_manager_enabled

  # Share fabric manager package and version with InSpec tests
  node.default['cluster']['nvidia']['fabricmanager']['package'] = fabric_manager_package
  node.default['cluster']['nvidia']['fabricmanager']['version'] = fabric_manager_version
  node_attributes "dump node attributes"

  action_install_package
end

action :configure do
  # Start nvidia fabric manager on NVSwitch enabled systems, except for GB200 which does not need it.
  if enable_fabric_manager? && !is_gb200_node?
    service fabric_manager_service do
      action %i(start enable)
      supports status: true
    end
  end
end

def _fabric_manager_enabled
  # NVIDIA Fabric Manager not present on ARM
  !arm_instance? && _nvidia_enabled
end

def _nvidia_enabled
  nvidia_enabled.nil? ? ['yes', true, 'true'].include?(node['cluster']['nvidia']['enabled']) : nvidia_enabled
end

def _nvidia_driver_version
  nvidia_driver_version || node['cluster']['nvidia']['driver_version']
end

def fabric_manager_package
  'nvidia-fabricmanager'
end

# The systemd service name for fabric manager.
# On AL2, the RPM package is named 'nvidia-fabric-manager' but the
# systemd service unit is 'nvidia-fabricmanager' (no hyphen between
# 'fabric' and 'manager'), matching all other platforms.
def fabric_manager_service
  'nvidia-fabricmanager'
end

def fabric_manager_version
  _nvidia_driver_version
end
