#
# Cookbook Name:: cfncluster
# Recipe:: sge_install
#
# Copyright (c) 2015 Amazon Web Services, All Rights Reserved.

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
    sh scripts/bootstrap.sh -no-java -no-jni -no-herd
    ./aimk -pam -no-remote -no-java -no-jni -no-herd
    ./aimk -man -no-java -no-jni -no-herd
    scripts/distinst -local -allall -noexit
    mkdir $SGE_ROOT
    echo instremote=false >> distinst.private
    gearch=`dist/util/arch`
    echo 'y'| scripts/distinst -local -allall ${gearch}
  EOF
  # TODO: Fix, so it works for upgrade
  creates '/opt/sge/bin/lx-amd64/sge_qmaster'
end

# Setup cluster user
  user "sgeadmin" do
  supports :manage_home => true
  comment 'sgeadmin user'
  home "/home/sgeadmin"
  system true
  shell '/bin/bash'
end

# Install publish_pending

