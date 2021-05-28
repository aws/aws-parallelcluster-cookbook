# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: slurm_install
#
# Copyright 2013-2015 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

return if node['conditions']['ami_bootstrapped']

include_recipe 'aws-parallelcluster::base_install'
include_recipe 'aws-parallelcluster::munge_install'
include_recipe 'aws-parallelcluster::pmix_install'

package %w[slurm* libslurm*] do
  action :purge
end

# Setup slurm group
group node['cluster']['slurm']['group'] do
  comment 'slurm group'
  gid node['cluster']['slurm']['group_id']
  system true
end

# Setup slurm user
user node['cluster']['slurm']['user'] do
  comment 'slurm user'
  uid node['cluster']['slurm']['user_id']
  gid node['cluster']['slurm']['group_id']
  # home is mounted from the head node
  manage_home ['HeadNode', nil].include?(node['cluster']['node_type'])
  home "/home/#{node['cluster']['slurm']['user']}"
  system true
  shell '/bin/bash'
end

case node['cluster']['node_type']
when 'HeadNode', nil
  slurm_tarball = "#{node['cluster']['sources_dir']}/slurm-#{node['cluster']['slurm']['version']}.tar.gz"

  # Get slurm tarball
  remote_file slurm_tarball do
    source node['cluster']['slurm']['url']
    mode '0644'
    retries 3
    retry_delay 5
    not_if { ::File.exist?(slurm_tarball) }
  end

  # Validate the authenticity of the downloaded archive based on the checksum published by SchedMD
  ruby_block "Validate Slurm Tarball Checksum" do
    block do
      require 'digest'
      checksum = Digest::SHA1.file(slurm_tarball).hexdigest # nosemgrep
      raise "Downloaded Tarball Checksum #{checksum} does not match expected checksum #{node['cluster']['slurm']['sha1']}" if checksum != node['cluster']['slurm']['sha1']
    end
  end

  # Install Slurm
  bash 'make install' do
    user 'root'
    group 'root'
    cwd Chef::Config[:file_cache_path]
    code <<-SLURM
      set -e

      # python3 is required to build slurm >= 20.02
      source #{node['cluster']['cookbook_virtualenv_path']}/bin/activate

      tar xf #{slurm_tarball}
      cd slurm-slurm-#{node['cluster']['slurm']['version']}
      ./configure --prefix=/opt/slurm --with-pmix=/opt/pmix
      CORES=$(grep processor /proc/cpuinfo | wc -l)
      make -j $CORES
      make install
      make install-contrib
      deactivate
    SLURM
    # TODO: Fix, so it works for upgrade
    creates '/opt/slurm/bin/srun'
  end

  # Copy required licensing files
  directory "#{node['cluster']['license_dir']}/slurm"

  bash 'copy license stuff' do
    user 'root'
    group 'root'
    cwd Chef::Config[:file_cache_path]
    code <<-SLURMLICENSE
      set -e
      cd slurm-slurm-#{node['cluster']['slurm']['version']}
      cp -v COPYING #{node['cluster']['license_dir']}/slurm/COPYING
      cp -v DISCLAIMER #{node['cluster']['license_dir']}/slurm/DISCLAIMER
      cp -v LICENSE.OpenSSL #{node['cluster']['license_dir']}/slurm/LICENSE.OpenSSL
      cp -v README.rst #{node['cluster']['license_dir']}/slurm/README.rst
    SLURMLICENSE
    # TODO: Fix, so it works for upgrade
    creates "#{node['cluster']['license_dir']}/slurm/README.rst"
  end

  # Install PerlSwitch
  case node['platform']
  when 'ubuntu'
    package 'libswitch-perl' do
      retries 3
      retry_delay 5
    end
  when 'centos', 'amazon'
    package 'perl-Switch' do
      retries 3
      retry_delay 5
    end
  end

when 'ComputeFleet'
  # Created Slurm shared mount point
  directory "/opt/slurm" do
    mode '1777'
    owner 'root'
    group 'root'
    action :create
  end
end

cookbook_file '/etc/init.d/slurm' do
  source 'slurm-init'
  owner 'root'
  group 'root'
  mode '0755'
  action :create
  only_if { node['platform_family'] == 'debian' && !node['init_package'] == 'systemd' }
end
