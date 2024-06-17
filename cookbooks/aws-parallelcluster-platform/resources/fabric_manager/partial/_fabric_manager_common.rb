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
  # Start nvidia fabric manager on NVSwitch enabled systems
  if get_nvswitches > 1
    service 'nvidia-fabricmanager' do
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
  nvidia_enabled.nil? ? ['yes', true].include?(node['cluster']['nvidia']['enabled']) : nvidia_enabled
end

def _nvidia_driver_version
  nvidia_driver_version || node['cluster']['nvidia']['driver_version']
end

# Get number of nv switches
def get_nvswitches
  #  A100 (P4) and H100(P5) systems have NVSwitches
  # NVSwitch device id is 10de:1af1 for P4 instance
  # NVSwitch device id is 10de:22a3 for P5 instance
  nvswitch_check_p4 = shell_out("lspci -d 10de:1af1 | wc -l")
  nvswitch_check_p5 = shell_out("lspci -d 10de:22a3 | wc -l")
  nvswitch_check_p4.stdout.strip.to_i + nvswitch_check_p5.stdout.strip.to_i
end
