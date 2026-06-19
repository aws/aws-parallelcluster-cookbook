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

# Install the NVIDIA driver local-repo deb (downloaded earlier) and enroll its signing key.
action :install_driver_repo do
  dpkg_package driver_repo_package_name do
    source driver_repo_package_path
    retries 3
    retry_delay 5
  end

  execute "Install keyring for #{driver_repo_package_name}" do
    command "cp /var/#{driver_repo_package_name}/nvidia-driver-*-keyring.gpg /usr/share/keyrings/"
  end
end

# Install the CUDA local-repo deb (downloaded earlier) and enroll its signing key.
action :install_cuda_repo do
  dpkg_package cuda_repo_package_name do
    source cuda_repo_package_path
    retries 3
    retry_delay 5
  end

  execute "Install keyring for #{cuda_repo_package_name}" do
    command "cp /var/#{cuda_repo_package_name}/cuda-*-keyring.gpg /usr/share/keyrings/"
  end
end

action :refresh_repo_cache do
  apt_update 'Update apt cache for NVIDIA local repos' do
    action :update
  end
end

# Refresh apt's metadata, e.g. after removing the local repos, so their package
# lists are no longer offered to apt.
action :refresh_metadata do
  apt_update 'Refresh apt metadata after removing NVIDIA local repos' do
    action :update
  end
end

# Purge (not just remove) the local-repo package so its apt source list
# (/etc/apt/sources.list.d/*.list, shipped as a conffile) is deleted too.
# A plain remove keeps that conffile pointing at the now-deleted /var/<repo>
# directory, which makes the subsequent `apt-get update` fail.
def local_repo_remove_action
  :purge
end

def arch_suffix
  arm_instance? ? 'arm64' : 'amd64'
end

# NVIDIA driver local-repo installer deb file, e.g.
# nvidia-driver-local-repo-ubuntu2204-580.105.08_1.0-1_amd64.deb
def driver_repo_package_file
  "#{driver_repo_package_name}_1.0-1_#{arch_suffix}.deb"
end

# CUDA local-repo installer deb file, e.g.
# cuda-repo-ubuntu2204-13-0-local_13.0.2-580.95.05-1_amd64.deb
def cuda_repo_package_file
  "#{cuda_repo_package_name}_#{cuda_version}-#{node['cluster']['nvidia']['cuda']['driver_version_suffix']}-1_#{arch_suffix}.deb"
end
