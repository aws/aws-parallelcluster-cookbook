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

provides :install_packages, platform: 'redhat' do |node|
  node['platform_version'].to_i >= 8
end

use 'partial/_install_packages_common.rb'
use 'partial/_install_packages_rhel_amazon.rb'

def default_packages
  # environment-modules required by EFA, Intel MPI and ARM PL
  # Removed libssh2-devel from base_packages since is not shipped by RedHat 8 and in conflict with package libssh-0.9.6-3.el8.x86_64
  # iptables needed for IMDS setup
  packages = %w(vim ksh tcsh zsh openssl-devel ncurses-devel pam-devel net-tools openmotif-devel
     libXmu-devel hwloc-devel libdb-devel tcl-devel automake autoconf libtool
     httpd boost-devel mlocate R atlas-devel
     blas-devel libffi-devel dkms libedit-devel jq
     libical-devel sendmail libxml2-devel libglvnd-devel
     libgcrypt-devel libevent-devel glibc-static bind-utils
     iproute NetworkManager-config-routing-rules python3 python3-pip iptables libcurl-devel yum-plugin-versionlock
     coreutils moreutils curl environment-modules gcc gcc-c++ bzip2)

  if aws_region.start_with?("us-iso")
    packages -= %w(openmotif-devel hwloc-devel R blas-devel dkms libedit-devel glibc-static
       NetworkManager-config-routing-rules yum-plugin-versionlock moreutils)
  end

  packages
end

action :install_extras do
  if aws_region.start_with?("us-iso")
    remote_file "epel_deps.tar.gz" do
      source "#{node['cluster']['artifacts_s3_url']}/dependencies/epel/rhel8/x86_64/epel_deps.tar.gz"
      mode '0644'
      retries 3
      retry_delay 5
      action :create_if_missing
    end

    bash 'yum install missing deps' do
      user 'root'
      group 'root'
      code <<-REQ
      set -e
      tar xzf epel_deps.tar.gz
      cd epel
      yum install -y * 2>/dev/null
      REQ
    end
  end
end
