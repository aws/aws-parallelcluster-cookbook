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

action :install_package do
  return unless nvidia_enabled?

  bash "Install enroot" do
    user 'root'
    cwd node['cluster']['sources_dir']
    code <<-ENROOT_INSTALL
      set -e
      apt-get install -y jq squashfs-tools parallel fuse-overlayfs pigz squashfuse zstd
      curl -fSsL -O #{enroot_url}
      curl -fSsL -O #{enroot_caps_url}
      apt install -y ./*.deb

      ln -s /usr/share/enroot/hooks.d/50-slurm-pmi.sh /etc/enroot/hooks.d/
      ln -s /usr/share/enroot/hooks.d/50-slurm-pytorch.sh /etc/enroot/hooks.d/
      mkdir -p /etc/sysconfig
      echo "PATH=/opt/slurm/sbin:/opt/slurm/bin:$(bash -c 'source /etc/environment ; echo $PATH')" >> /etc/sysconfig/slurmd

    ENROOT_INSTALL
    retries 3
    retry_delay 5
  end
end

def enroot_url
  "https://github.com/NVIDIA/enroot/releases/download/v#{package_version}/enroot_#{package_version}-1_#{arch_suffix}.deb"
end

def enroot_caps_url
  "https://github.com/NVIDIA/enroot/releases/download/v#{package_version}/enroot+caps_#{package_version}-1_#{arch_suffix}.deb"
end

def arch_suffix
  arm_instance? ? 'arm64' : 'amd64'
end
