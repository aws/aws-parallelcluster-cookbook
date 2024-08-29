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

provides :install_packages, platform: 'ubuntu', platform_version: '22.04'
unified_mode true
default_action :setup

use 'partial/_install_packages_common.rb'
use 'partial/_install_packages_debian.rb'

def default_packages
  # environment-modules required by EFA, Intel MPI and ARM PL
  # iptables needed for IMDS setup
  %w(vim ksh tcsh zsh libssl-dev ncurses-dev libpam-dev net-tools libhwloc-dev dkms
     tcl-dev automake autoconf libtool librrd-dev libapr1-dev libconfuse-dev
     apache2 libboost-dev libdb-dev libncurses5-dev libpam0g-dev libxt-dev
     libmotif-dev libxmu-dev libxft-dev man-db jq
     r-base libblas-dev libffi-dev libxml2-dev
     libgcrypt20-dev libevent-dev iproute2 python3 python3-pip
     libatlas-base-dev libglvnd-dev iptables libcurl4-openssl-dev
     coreutils moreutils curl python3-parted environment-modules libdbus-1-dev dos2unix)
end
