# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: _master_slurm_config
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

# Export /opt/slurm
nfs_export "/opt/slurm" do
  network node['cfncluster']['ec2-metadata']['vpc-ipv4-cidr-blocks']
  writeable true
  options ['no_root_squash']
end

# Ensure config directory is in place
directory '/opt/slurm/etc' do
  user 'root'
  group 'root'
  mode '0755'
end

# Create directory configured as StateSaveLocation
directory '/var/spool/slurm.state' do
  user 'slurm'
  group 'slurm'
  mode '0700'
end

template '/opt/slurm/etc/slurm.conf' do
  source 'slurm/slurm.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

template '/opt/slurm/etc/gres.conf' do
  source 'slurm/gres.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

# Copy pcluster config generator and templates
remote_directory "#{node['cfncluster']['scripts_dir']}/slurm" do
  source 'slurm'
  mode '0755'
  action :create
  recursive true
end

# Copy cluster config file from S3 URI
execute "copy_cluster_config_from_s3" do
  command "#{node['cfncluster']['cookbook_virtualenv_path']}/bin/aws s3 cp #{node['cfncluster']['cluster_config_s3_uri']} #{node['cfncluster']['cluster_config_path']}"\
          " --region #{node['cfncluster']['cfn_region']}"
end

# Ensure slurm plugin directory is in place
directory "#{node['cfncluster']['slurm_plugin_dir']}" do
  user 'slurm'
  group 'slurm'
  mode '0755'
  action :create
  recursive true
end

# Generate pcluster specific configs
execute "generate_pcluster_slurm_configs" do
  command "#{node['cfncluster']['cookbook_virtualenv_path']}/bin/python #{node['cfncluster']['scripts_dir']}/slurm/pcluster_slurm_config_generator.py"\
          " --output-directory /opt/slurm/etc/ --template-directory #{node['cfncluster']['scripts_dir']}/slurm/templates/ --input-file #{node['cfncluster']['cluster_config_path']}"
end

# alinux1 and centos6 use an old cgroup directory: /cgroup
# all other OSs use /sys/fs/cgroup, which is the default
template '/opt/slurm/etc/cgroup.conf' do
  source 'slurm/cgroup.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

cookbook_file '/opt/slurm/etc/slurm.sh' do
  source 'slurm.sh'
  owner 'root'
  group 'root'
  mode '0755'
end

cookbook_file '/opt/slurm/etc/slurm.csh' do
  source 'slurm.csh'
  owner 'root'
  group 'root'
  mode '0755'
end

template "#{node['cfncluster']['scripts_dir']}/slurm/slurm_resume" do
  source 'slurm/resume_program.erb'
  owner 'slurm'
  group 'slurm'
  mode '0744'
end

file "/var/log/parallelcluster/slurm_resume.log" do
  owner 'slurm'
  group 'slurm'
  mode '0644'
end

template "#{node['cfncluster']['slurm_plugin_dir']}/parallelcluster_slurm_resume.conf" do
  source 'slurm/parallelcluster_slurm_resume.conf.erb'
  owner 'slurm'
  group 'slurm'
  mode '0644'
end

template "#{node['cfncluster']['scripts_dir']}/slurm/slurm_suspend" do
  source 'slurm/suspend_program.erb'
  owner 'slurm'
  group 'slurm'
  mode '0744'
end

file "/var/log/parallelcluster/slurm_suspend.log" do
  owner 'slurm'
  group 'slurm'
  mode '0644'
end

template "#{node['cfncluster']['slurm_plugin_dir']}/parallelcluster_slurm_suspend.conf" do
  source 'slurm/parallelcluster_slurm_suspend.conf.erb'
  owner 'slurm'
  group 'slurm'
  mode '0644'
end

template "#{node['cfncluster']['slurm_plugin_dir']}/parallelcluster_clustermgtd.conf" do
  source 'slurm/parallelcluster_clustermgtd.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

# Create shared directory used to store clustermgtd heartbeat and computemgtd config
directory "/opt/slurm/etc/pcluster/.slurm_plugin" do
  user 'root'
  group 'root'
  mode '0644'
  action :create
  recursive true
end

# Put computemgtd config under /opt/slurm/etc/pcluster/.slurm_plugin so all compute nodes share a config
template "/opt/slurm/etc/pcluster/.slurm_plugin/parallelcluster_computemgtd.conf" do
  source 'slurm/parallelcluster_computemgtd.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

# Increase somaxconn to 1024 for large scale setting
execute "increase_somaxconn" do
  command "echo '1024' > /proc/sys/net/core/somaxconn"
end

cookbook_file '/etc/systemd/system/slurmctld.service' do
  source 'slurmctld.service'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
  only_if { node['init_package'] == 'systemd' }
end

if node['init_package'] == 'systemd'
  service "slurmctld" do
    supports restart: false
    action %i[enable start]
  end
else
  service "slurm" do
    supports restart: false
    action %i[enable start]
  end
end
