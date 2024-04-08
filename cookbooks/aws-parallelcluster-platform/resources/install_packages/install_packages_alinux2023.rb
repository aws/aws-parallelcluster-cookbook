# frozen_string_literal: true

# Copyright:: 2024 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

provides :install_packages, platform: 'amazon' do |node|
  node['platform_version'].to_i == 2023
end

use 'partial/_install_packages_common.rb'
use 'partial/_install_packages_rhel_amazon.rb'

def default_packages
  # environment-modules required by EFA, Intel MPI and ARM PL
  # Removed libssh2-devel from base_packages since is not shipped by RedHat 8 and in conflict with package libssh-0.9.6-3.el8.x86_64
  # iptables needed for IMDS setup
  # Removed curl since curl-minimal-8.5.0-1.amzn2023* is already shipped and conficts.
  # Or we can use full-featured curl if needed by running dnf install --allowerasing curl-full libcurl-full (https://docs.aws.amazon.com/linux/al2023/release-notes/relnotes-2022.0.20220824.html#major-changes-20220824)
  %w(ksh tcsh zsh openssl-devel ncurses-devel pam-devel net-tools
     libXmu-devel hwloc-devel libdb-devel tcl-devel automake autoconf libtool
     httpd boost-devel mlocate R atlas-devel
     blas-devel libffi-devel dkms libedit-devel jq
     libical-devel sendmail libxml2-devel libglvnd-devel
     libgcrypt-devel libevent-devel glibc-static bind-utils
     iproute python3 python3-pip libcurl-devel
     coreutils environment-modules gcc gcc-c++ bzip2)
end

def unsupported_packages
  # Using `sudo dnf supportinfo --pkg <PACKAGE_NAME>` to find if packages are available
  %w(vim openmotif-devel redhat-lsb python2 python2-pip NetworkManager-config-routing-rules iptables yum-plugin-versionlock moreutils)
end
