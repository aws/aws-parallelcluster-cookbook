# frozen_string_literal: true
#
# Copyright:: 2026 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

# Prepare the system for the driver meta-package install.
# Enable the requested module stream and refresh the cache, mirroring the NVIDIA RHEL
# installation guide.
# See https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/latest/red-hat-enterprise-linux.html
# We invoke `dnf module enable` directly rather than via the community `dnf_module`
# resource, because that resource silently no-ops on Amazon Linux 2023.
action :prepare_driver_install do
  execute 'Enable NVIDIA driver module' do
    command "dnf -y module enable nvidia-driver:#{nvidia_driver_module_stream} && dnf clean all"
    retries 3
    retry_delay 5
  end
end

# DKMS module stream enabled via `dnf module enable nvidia-driver:<stream>`.
# Open kernel modules -> 'open-dkms', proprietary -> 'latest-dkms'.
def nvidia_driver_module_stream
  nvidia_open_kernel_modules? ? 'open-dkms' : 'latest-dkms'
end
