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

def nvidia_nvlsm_package_full_name
  "#{nvidia_nvlsm_package}-#{nvidia_nvlsm_version}.#{arch_suffix}.rpm"
end

def arch_suffix
  arm_instance? ? 'aarch64' : 'x86_64'
end

def nvidia_nvlsm_checksum
  if arm_instance?
    'f21f14843c11ce64136fd1c3fa763b7511e18f160695f54b2a8d763776313539'
  else
    '88d5e52183bb5ee763eb864bbd119b591e7f45af32c52bd7ba0aa8f74fc19057'
  end
end

def nvidia_nvlsm_install_commands
  "yum install -y #{nvidia_nvlsm_package_full_name} && yum versionlock #{nvidia_nvlsm_package}"
end

def nvidia_nvlsm_install_dependencies_commands
  "yum install -y infiniband-diags libibumad"
end
