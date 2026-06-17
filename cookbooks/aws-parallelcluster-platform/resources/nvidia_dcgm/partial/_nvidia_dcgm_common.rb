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
  return unless _nvidia_dcgm_enabled
  # Skip if DCGM is already installed (e.g. DLAMI). Reinstalling a different
  # version breaks the preinstalled, version-pinned DCGM subpackages and leaves
  # the package manager in a broken state, failing later package installs.
  return if dcgmi_installed?

  action_install_package
end

def _nvidia_enabled
  nvidia_enabled.nil? ? ['yes', true, 'true'].include?(node['cluster']['nvidia']['enabled']) : nvidia_enabled
end

# True if DCGM is installed (regardless of version). Like nvidia-smi for the
# driver, the dcgmi binary is the single signal of a healthy install and is
# installed to /usr/bin on all platforms.
def dcgmi_installed?
  ::File.exist?('/usr/bin/dcgmi')
end

def package_version
  node['cluster']['nvidia']['dcgm_version']
end
