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

action :setup do
  return unless _fabric_manager_enabled
  return if fabric_manager_installed?

  # Share fabric manager package with InSpec tests
  node.default['cluster']['nvidia']['fabricmanager']['package'] = fabric_manager_package
  node_attributes "dump node attributes"

  package fabric_manager_package do
    retries 3
    retry_delay 5
  end

  action_lock_package_version
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

# True if Fabric Manager is already installed (e.g. shipped by the base image
# such as the DLAMI). nv-fabricmanager is installed to /usr/bin on all platforms.
def fabric_manager_installed?
  ::File.exist?('/usr/bin/nv-fabricmanager')
end

def _nvidia_enabled
  nvidia_enabled.nil? ? ['yes', true, 'true'].include?(node['cluster']['nvidia']['enabled']) : nvidia_enabled
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
