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

action :setup do
  # NVIDIA Fabric Manager not present on ARM
  return if arm_instance? || !(node['cluster']['nvidia']['enabled'] == 'yes' || node['cluster']['nvidia']['enabled'] == true)

  # Add NVIDIA repo for fabric manager and datacenter-gpu-manager
  nvidia_repo 'add nvidia repository' do
    action :add
  end

  action_install_package

  nvidia_repo 'remove nvidia repository' do
    action :remove
  end
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
