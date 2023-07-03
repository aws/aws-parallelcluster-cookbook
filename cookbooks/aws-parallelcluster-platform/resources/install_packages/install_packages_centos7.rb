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

provides :install_packages, platform: 'centos' do |node|
  node['platform_version'].to_i == 7
end

use 'partial/_install_packages_common.rb'
use 'partial/_install_packages_rhel_amazon.rb'

def default_packages
  # environment-modules required by EFA, Intel MPI and ARM PL
  # iptables needed for IMDS setup
  packages = %w(vim ksh tcsh zsh openssl-devel ncurses-devel pam-devel net-tools openmotif-devel
     libXmu-devel hwloc-devel libdb-devel tcl-devel automake autoconf pyparted libtool
     httpd boost-devel redhat-lsb mlocate R atlas-devel
     blas-devel libffi-devel dkms libedit-devel jq
     libical-devel sendmail libxml2-devel libglvnd-devel
     python python-pip libssh2-devel libgcrypt-devel libevent-devel glibc-static bind-utils
     iproute NetworkManager-config-routing-rules python3 python3-pip iptables libcurl-devel yum-plugin-versionlock
     coreutils moreutils curl environment-modules bzip2)

  # TODO: check if it is still relevant. Evaluate if it is worth to remove the package.
  if node['kernel']['machine'] == 'aarch64'
    # Do not install bind-utils on centos7+arm due to issue with package checksum
    packages -= %w(bind-utils)
  end

  packages
end
