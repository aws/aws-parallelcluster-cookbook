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
  "#{nvidia_nvlsm_package}_#{nvidia_nvlsm_version}_#{arch_suffix}.deb"
end

def arch_suffix
  arm_instance? ? 'arm64' : 'amd64'
end

def nvidia_nvlsm_checksum
  if arm_instance?
    '6bb405a3494d9fcb6dad6e641d02afb71fd4e2f6a2b4ed3d5cf6cbff22964eb3'
  else
    '61f280e469624c43eecb0e08305452887e02f73e4763252a41f728d1843f1cc5'
  end
end

def nvidia_nvlsm_install_commands
  "dpkg -i #{nvidia_nvlsm_package_full_name} && apt-mark hold #{nvidia_nvlsm_package}"
end

def nvidia_nvlsm_install_dependencies_commands
  "apt install -y infiniband-diags ibutils"
end
