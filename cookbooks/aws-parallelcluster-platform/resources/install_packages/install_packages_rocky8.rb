# frozen_string_literal: true

# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

provides :install_packages, platform: 'rocky' do |node|
  node['platform_version'].to_i >= 8
end

use 'partial/_install_packages_common.rb'
use 'partial/_install_packages_rhel_amazon.rb'

action :install_kernel_source do
  # Previous releases are moved into a vault area once a new minor release version is available for at least a week.
  # https://wiki.rockylinux.org/rocky/repo/#notes-on-devel
  bash "Install kernel source" do
    user 'root'
    code <<-INSTALL_KERNEL_SOURCE
    package="#{kernel_source_package}-#{kernel_source_package_version}"

    # try to install kernel source for a specific release version
    dnf install -y ${package} --releasever #{node['platform_version']}
    if [ $? -ne 0 ]; then
      # Previous releases are moved into a vault area once a new minor release version is available for at least a week.
      # https://wiki.rockylinux.org/rocky/repo/#notes-on-devel
      base_os_package_url="https://dl.rockylinux.org/vault/rocky/#{node['platform_version']}/BaseOS/#{node['kernel']['machine']}/os/Packages/k/${package}.rpm"
      appstream_package_url="https://dl.rockylinux.org/vault/rocky/#{node['platform_version']}/AppStream/#{node['kernel']['machine']}/os/Packages/k/${package}.rpm"
      base_os_status_code=$(curl --write-out '%{http_code}' --silent --output /dev/null ${base_os_package_url})
      appstream_status_code=$(curl --write-out '%{http_code}' --silent --output /dev/null ${appstream_package_url})
      set -e
      if [ $base_os_status_code != 404 ]; then
        dnf install -y ${base_os_package_url}
      elif [ $appstream_status_code != 404 ]; then
        dnf install -y ${appstream_package_url}
      fi
    fi
    dnf clean all
    INSTALL_KERNEL_SOURCE
  end unless on_docker?
end

def kernel_source_package_version
  node['kernel']['release']
end

def default_packages
  # environment-modules required by EFA, Intel MPI and ARM PL
  # iptables needed for IMDS setup
  packages = %w(vim ksh tcsh zsh openssl-devel ncurses-devel pam-devel net-tools openmotif-devel
     libXmu-devel hwloc-devel libdb-devel tcl-devel automake autoconf libtool
     httpd boost-devel mlocate R atlas-devel
     blas-devel libffi-devel dkms libedit-devel jq
     libical-devel sendmail libxml2-devel libglvnd-devel
     libgcrypt-devel libevent-devel glibc-static bind-utils
     iproute NetworkManager-config-routing-rules python3 python3-pip iptables libcurl-devel yum-plugin-versionlock
     moreutils curl environment-modules gcc gcc-c++ bzip2 dos2unix)
  packages.append("coreutils") unless on_docker?  # on docker image coreutils conflict with coreutils-single, already installed on it
  packages
end
