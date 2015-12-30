#
# Cookbook Name:: cfncluster
# Recipe:: slurm_install
#
# Copyright 2013-2015 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Amazon Software License (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/asl/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

include_recipe 'cfncluster::base_install'
include_recipe 'cfncluster::munge_install'

slurm_tarball = "#{node['cfncluster']['sources_dir']}/slurm-#{node['cfncluster']['slurm']['version']}.tar.gz"

# Get slurm tarball
remote_file slurm_tarball do
  source node['cfncluster']['slurm']['url']
  mode '0644'
  # TODO: Add version or checksum checks
  not_if { ::File.exists?(slurm_tarball) }
end

# Install Slurm
bash 'make install' do
  user 'root'
  group 'root'
  cwd Chef::Config[:file_cache_path]
  code <<-EOF
    tar xf #{slurm_tarball}
    cd slurm-slurm-#{node['cfncluster']['slurm']['version']}
    ./configure --prefix=/opt/slurm
    CORES=$(grep processor /proc/cpuinfo | wc -l)
    make -j $CORES
    make install
  EOF
  # TODO: Fix, so it works for upgrade
  creates '/opt/slurm/bin/srun'
end

# Setup slurm user
  user "slurm" do
  supports :manage_home => true
  comment 'slurm user'
  home "/home/slurm"
  system true
  shell '/bin/bash'
end

if node['platform_family'] == 'debian'
  cookbook_file '/etc/init.d/slurm' do
    source 'slurm-init'
    owner 'root'
    group 'root'
    mode '0755'
    action :create
  end
end
  
