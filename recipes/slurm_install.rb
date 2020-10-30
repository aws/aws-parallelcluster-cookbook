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

case node['cfncluster']['cfn_node_type']
when 'MasterServer', nil
  slurm_tarball = "#{node['cfncluster']['sources_dir']}/slurm-#{node['cfncluster']['slurm']['version']}.tar.gz"

  # Get slurm tarball
  remote_file slurm_tarball do
    source node['cfncluster']['slurm']['url']
    mode '0644'
    retries 3
    retry_delay 5
    not_if { ::File.exist?(slurm_tarball) }
  end

  # Validate the authenticity of the downloaded archive based on the checksum published by SchedMD
  ruby_block "Validate Slurm Tarball Checksum" do
    block do
      require 'digest'
      checksum = Digest::SHA1.file(slurm_tarball).hexdigest
      raise "Downloaded Tarball Checksum #{checksum} does not match expected checksum #{node['cfncluster']['slurm']['sha1']}" if checksum != node['cfncluster']['slurm']['sha1']
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
      source #{node['cfncluster']['cookbook_virtualenv_path']}/bin/activate

      tar xf #{slurm_tarball}
      cd slurm-#{node['cfncluster']['slurm']['version']}
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

  # Setup slurm user
  user "slurm" do
    manage_home true
    comment 'slurm user'
    home "/home/slurm"
    system true
    shell '/bin/bash'
  end

  # Copy required licensing files
  directory "#{node['cfncluster']['license_dir']}/slurm"

  bash 'copy license stuff' do
    user 'root'
    group 'root'
    cwd Chef::Config[:file_cache_path]
    code <<-SLURMLICENSE
      set -e
      cd slurm-#{node['cfncluster']['slurm']['version']}
      cp -v COPYING #{node['cfncluster']['license_dir']}/slurm/COPYING
      cp -v DISCLAIMER #{node['cfncluster']['license_dir']}/slurm/DISCLAIMER
      cp -v LICENSE.OpenSSL #{node['cfncluster']['license_dir']}/slurm/LICENSE.OpenSSL
      cp -v README.rst #{node['cfncluster']['license_dir']}/slurm/README.rst
    SLURMLICENSE
    # TODO: Fix, so it works for upgrade
    creates "#{node['cfncluster']['license_dir']}/slurm/README.rst"
  end

  # Install PerlSwitch
  if node['platform'] == 'ubuntu'
    package 'libswitch-perl' do
      retries 3
      retry_delay 5
    end
  elsif node['platform'] == 'centos' || node['platform'] == 'amazon'
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

  # Setup slurm user without creating the home (mounted from master)
  user "slurm" do
    manage_home false
    comment 'slurm user'
    home "/home/slurm"
    system true
    shell '/bin/bash'
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
