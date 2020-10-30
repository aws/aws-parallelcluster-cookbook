# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: sge_install
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

case node['cfncluster']['cfn_node_type']
when 'MasterServer', nil
  sge_tarball = "#{node['cfncluster']['sources_dir']}/sge-#{node['cfncluster']['sge']['version']}.tar.gz"

  # SGE preinstall script
  cookbook_file 'sge_preinstall.sh' do
    path '/tmp/sge_preinstall.sh'
    user 'root'
    group 'root'
    mode '0644'
  end

  if node['platform'] == 'centos' && node['platform_version'].to_i >= 8
    # Additional patch files required for CentOS 8
    cookbook_file 'sge-openssl.patch' do
      path '/tmp/sge-openssl.patch'
    end
    cookbook_file 'sge-tcsh.patch' do
      path '/tmp/sge-tcsh.patch'
    end
    cookbook_file 'sge-qmake.patch' do
      path '/tmp/sge-qmake.patch'
    end
  end

  execute 'sge_preinstall' do
    user 'root'
    group 'root'
    cwd "/tmp"
    environment(
      'VERSION' => node['cfncluster']['sge']['version'],
      'TARBALL_ROOT_DIR' => "sge-#{node['cfncluster']['sge']['version']}",
      'TARBALL_PATH' => sge_tarball,
      'TARBALL_URL' => node['cfncluster']['sge']['url'],
      'REGION' => node['cfncluster']['cfn_region']
    )
    command 'sh /tmp/sge_preinstall.sh'
    not_if { ::File.exist?(sge_tarball) }
  end

  # Additional aimk flags required for Centos8 because tirpc library is
  # in /usr/include instead of /usr/local/include
  c_flags = value_for_platform(
    'centos' => { '>=8' => "-I/usr/include/tirpc" },
    'default' => ""
  )
  ld_flags = value_for_platform(
    'centos' => { '>=8' => "-ltirpc" },
    'default' => ""
  )

  # Install SGE
  architecture_id = arm_instance? ? "arm64" : "amd64"
  qmaster_bin_dir = "/opt/sge/bin/lx-#{architecture_id}/sge_qmaster"
  bash 'make install' do
    user 'root'
    group 'root'
    cwd Chef::Config[:file_cache_path]
    environment(
      'SGE_ROOT' => '/opt/sge',
      'SGE_INPUT_CFLAGS' => c_flags.to_s,
      'SGE_INPUT_LDFLAGS' => ld_flags.to_s
    )
    code <<-SGE
      set -e
      tar xf #{sge_tarball}
      cd sge-#{node['cfncluster']['sge']['version']}/source
      CORES=$(grep processor /proc/cpuinfo | wc -l)
      sh scripts/bootstrap.sh -no-java -no-jni -no-herd
      ./aimk -pam -no-remote -no-java -no-jni -no-herd -parallel $CORES
      ./aimk -man -no-java -no-jni -no-herd -parallel $CORES
      mkdir $SGE_ROOT
      echo instremote=false >> distinst.private
      gearch=`dist/util/arch`
      echo 'y'| scripts/distinst -local -allall ${gearch}
    SGE
    # TODO: Fix, so it works for upgrade
    creates qmaster_bin_dir
  end

  # Copy qconf utils (Downloaded from https://arc.liv.ac.uk/SGE/downloads/qconf_scripts.tar.gz)
  cookbook_file 'qconf_scripts.tar.gz' do
    path '/opt/sge/util/qconf_scripts.tar.gz'
    user 'root'
    group 'root'
    mode '0644'
  end

  bash "extract_qconf_util" do
    code <<-EXTRACTQCONFUTIL
      set -e
      tar xf /opt/sge/util/qconf_scripts.tar.gz -C /opt/sge/util --strip-components=1 --no-same-permissions --no-same-owner
      # applying small patch for a bug in sge_edit_mod_attr script
      # [[]] is incompatible with dash which is the default sh in ubuntu
      sed -i 's/if \\[\\[ $cc -eq 0 ]]/if [ $cc -eq 0 ]/g' /opt/sge/util/sge_edit_mod_attr
    EXTRACTQCONFUTIL
    creates '/opt/sge/util/sge_edit_mod_attr'
  end

  # Disbale the AddQueue, so that we can manage slots per instance
  replace_or_add "AddQueue" do
    path "/opt/sge/inst_sge"
    pattern "AddQueue"
    line "#AddQueue"
  end

  # Only on CentOS/RHEL7 update the initd
  if node['platform_family'] == 'rhel' && node['platform'] != 'amazon'
    execute 'sed' do
      command 'sed -i s/remote_fs/local_fs/g /opt/sge/util/rctemplates/sgemaster_template'
    end
    execute 'sed' do
      command 'sed -i s/remote_fs/local_fs/g /opt/sge/util/rctemplates/sgeexecd_template'
    end
  end

  # Setup sgeadmin user
  user "sgeadmin" do
    manage_home true
    comment 'sgeadmin user'
    home "/home/sgeadmin"
    system true
    shell '/bin/bash'
  end

  # Copy required licensing files
  directory "#{node['cfncluster']['license_dir']}/sge"

  bash 'copy license stuff' do
    user 'root'
    group 'root'
    cwd Chef::Config[:file_cache_path]
    code <<-SGELICENSE
      set -e
      cd sge-#{node['cfncluster']['sge']['version']}/LICENCES
      cp -v SISSL #{node['cfncluster']['license_dir']}/sge/SISSL
    SGELICENSE
    # TODO: Fix, so it works for upgrade
    creates "#{node['cfncluster']['license_dir']}/sge/SISSL"
  end
when 'ComputeFleet'
  # Created SGE shared mount point
  directory "/opt/sge" do
    mode '1777'
    owner 'root'
    group 'root'
    action :create
  end

  # Setup sgeadmin user without creating the home (mounted from master)
  user "sgeadmin" do
    manage_home false
    comment 'sgeadmin user'
    home "/home/sgeadmin"
    system true
    shell '/bin/bash'
  end
end
