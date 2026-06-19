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

# Install the NVIDIA driver local-repo rpm (downloaded earlier).
action :install_driver_repo do
  rpm_package driver_repo_package_name do
    source driver_repo_package_path
    retries 3
    retry_delay 5
  end
end

# Install the CUDA local-repo rpm (downloaded earlier).
action :install_cuda_repo do
  rpm_package cuda_repo_package_name do
    source cuda_repo_package_path
    retries 3
    retry_delay 5
  end
end

action :refresh_repo_cache do
  execute 'Refresh dnf metadata for NVIDIA local repos' do
    command 'dnf clean all'
  end

  dnf_package 'Update dnf cache for NVIDIA local repos' do
    action :flush_cache
  end
end

# Refresh dnf's on-disk metadata, e.g. after removing the local repos, so their
# package lists are no longer offered to dnf.
action :refresh_metadata do
  execute 'Refresh dnf metadata after removing NVIDIA local repos' do
    command 'dnf clean all'
  end
end

# rpm has no purge semantics; a plain remove already deletes the repo's
# .repo file, so removing the local-repo package is sufficient.
def local_repo_remove_action
  :remove
end

def arch_suffix
  arm_instance? ? 'aarch64' : 'x86_64'
end

# Default to the equivalent RHEL local repo. Platforms that publish their own
# local repo (e.g. Amazon Linux 2023) override this in their platform resource.
def local_repo_platform
  "rhel#{node['platform_version'].to_i}"
end

# NVIDIA driver local-repo installer rpm file, e.g.
# nvidia-driver-local-repo-amzn2023-580.105.08-1.0-1.x86_64.rpm
def driver_repo_package_file
  "#{driver_repo_package_name}-1.0-1.#{arch_suffix}.rpm"
end

# CUDA local-repo installer rpm file, e.g.
# cuda-repo-amzn2023-13-0-local-13.0.2_580.95.05-1.x86_64.rpm
def cuda_repo_package_file
  "#{cuda_repo_package_name}-#{cuda_version}_#{node['cluster']['nvidia']['cuda']['driver_version_suffix']}-1.#{arch_suffix}.rpm"
end
