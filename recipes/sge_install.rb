#
# Cookbook Name:: cfncluster
# Recipe:: sge_install
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

sge_tarball = "#{node['cfncluster']['sources_dir']}/sge-#{node['cfncluster']['sge']['version']}.tar.gz"

# Get SGE tarball
remote_file sge_tarball do
  source node['cfncluster']['sge']['url']
  mode '0644'
  # TODO: Add version or checksum checks
  not_if { ::File.exists?(sge_tarball) }
end

# Install SGE
bash 'make install' do
  user 'root'
  group 'root'
  cwd Chef::Config[:file_cache_path]
  environment 'SGE_ROOT' => '/opt/sge'
  code <<-EOF
    tar xf #{sge_tarball}
    cd sge*/source
    CORES=$(grep processor /proc/cpuinfo | wc -l)
    sh scripts/bootstrap.sh -no-java -no-jni -no-herd
    ./aimk -pam -no-remote -no-java -no-jni -no-herd -parallel $CORES
    ./aimk -man -no-java -no-jni -no-herd -parallel $CORES
    scripts/distinst -local -allall -noexit
    mkdir $SGE_ROOT
    echo instremote=false >> distinst.private
    gearch=`dist/util/arch`
    echo 'y'| scripts/distinst -local -allall ${gearch}
  EOF
  # TODO: Fix, so it works for upgrade
  creates '/opt/sge/bin/lx-amd64/sge_qmaster'
end

# Only on CentOS/RHEL7 update the initd
if node['platform_family'] == 'rhel' && node['platform_version'].to_i >= 7 && node['platform'] != 'amazon'
  execute 'sed' do
    command 'sed -i s/remote_fs/local_fs/g /opt/sge/util/rctemplates/sgemaster_template'
  end
  execute 'sed' do
    command 'sed -i s/remote_fs/local_fs/g /opt/sge/util/rctemplates/sgeexecd_template'
  end
end

# Setup sgeadmin user
user "sgeadmin" do
  supports :manage_home => true
  comment 'sgeadmin user'
  home "/home/sgeadmin"
  system true
  shell '/bin/bash'
end
