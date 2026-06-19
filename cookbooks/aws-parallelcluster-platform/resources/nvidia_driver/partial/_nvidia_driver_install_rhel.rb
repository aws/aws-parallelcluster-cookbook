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

action :install_driver do
  # Install the driver from the NVIDIA local repo's DKMS module stream.
  # The CUDA/driver local repos are registered earlier in the nvidia install
  # recipe, where the dnf metadata is also refreshed (`dnf clean all`) so the
  # local repo's module metadata is visible here.
  #
  # We invoke `dnf module enable` directly rather than via the community
  # `dnf_module` resource: that resource only treats platform_family 'rhel' (and
  # fedora) as module-capable, so it silently no-ops on Amazon Linux 2023
  # (platform_family 'amazon').
  #
  # Enable the requested module stream (open vs proprietary), then install the
  # matching driver meta-package, mirroring the NVIDIA RHEL installation guide.
  # See https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/latest/red-hat-enterprise-linux.html
  execute 'Enable NVIDIA driver module' do
    command "dnf -y module enable nvidia-driver:#{nvidia_driver_module_stream}"
    retries 3
    retry_delay 5
  end

  dnf_package nvidia_driver_package do
    flush_cache before: true
    retries 3
    retry_delay 5
  end
end

# Install the extra driver packages from the NVIDIA local repo.
action :install_extra_packages do
  new_resource.extra_driver_packages.split(',').each do |pkg|
    dnf_package pkg do
      retries 3
      retry_delay 5
    end
  end
end

# DKMS module stream enabled via `dnf module enable nvidia-driver:<stream>`.
# Open kernel modules -> 'open-dkms', proprietary -> 'latest-dkms'.
def nvidia_driver_module_stream
  nvidia_open_kernel_modules? ? 'open-dkms' : 'latest-dkms'
end

# Driver meta-package installed from the local repo.
# Open kernel modules -> 'nvidia-open', proprietary -> 'cuda-drivers'.
def nvidia_driver_package
  nvidia_open_kernel_modules? ? 'nvidia-open' : 'cuda-drivers'
end
