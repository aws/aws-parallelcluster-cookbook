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

provides :install_packages, platform: 'amazon', platform_version: '2'
unified_mode true
default_action :setup

use 'partial/_install_packages_common.rb'
use 'partial/_install_packages_rhel_amazon.rb'

def default_packages
  # environment-modules required by EFA, Intel MPI and ARM PL
  # iptables needed for IMDS setup
  %w(vim ksh tcsh zsh openssl-devel ncurses-devel pam-devel net-tools openmotif-devel
     libXmu-devel hwloc-devel libdb-devel tcl-devel automake autoconf pyparted libtool
     httpd boost-devel system-lsb mlocate atlas-devel glibc-static iproute
     libffi-devel dkms libedit-devel sendmail cmake byacc libglvnd-devel libgcrypt-devel libevent-devel
     libxml2-devel perl-devel tar gzip bison flex gcc gcc-c++ patch
     rpm-build rpm-sign system-rpm-config cscope ctags diffstat doxygen elfutils
     gcc-gfortran git indent intltool patchutils rcs subversion swig systemtap curl
     jq wget python-pip NetworkManager-config-routing-rules
     python3 python3-pip iptables libcurl-devel yum-plugin-versionlock
     coreutils moreutils environment-modules bzip2 dos2unix)
end

action :install_extras do
  # In the case of AL2, there are more packages to install via extras
  # Install R via amazon linux extras
  ['R3.4'].each do |topic|
    alinux_extras_topic topic
  end
end
