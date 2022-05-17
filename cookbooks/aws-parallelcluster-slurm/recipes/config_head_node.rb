# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-slurm
# Recipe:: config_head_node
#
# Copyright:: 2013-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

setup_munge_head_node

# Export /opt/slurm
nfs_export "#{node['cluster']['slurm']['install_dir']}" do
  network get_vpc_cidr_list
  writeable true
  options ['no_root_squash']
end

# Ensure config directory is in place
directory "#{node['cluster']['slurm']['install_dir']}/etc" do
  user 'root'
  group 'root'
  mode '0755'
end

# Create directory configured as StateSaveLocation
directory '/var/spool/slurm.state' do
  user node['cluster']['slurm']['user']
  group node['cluster']['slurm']['group']
  mode '0700'
end

template "#{node['cluster']['slurm']['install_dir']}/etc/slurm.conf" do
  source 'slurm/slurm.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

template "#{node['cluster']['slurm']['install_dir']}/etc/gres.conf" do
  source 'slurm/gres.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

# Copy pcluster config generator and templates
remote_directory "#{node['cluster']['scripts_dir']}/slurm" do
  source 'head_node_slurm/slurm'
  mode '0755'
  action :create
  recursive true
end

unless virtualized?
  # Generate pcluster specific configs
  no_gpu = nvidia_installed? ? "" : "--no-gpu"
  execute "generate_pcluster_slurm_configs" do
    command "#{node['cluster']['cookbook_virtualenv_path']}/bin/python #{node['cluster']['scripts_dir']}/slurm/pcluster_slurm_config_generator.py"\
            " --output-directory #{node['cluster']['slurm']['install_dir']}/etc/ --template-directory #{node['cluster']['scripts_dir']}/slurm/templates/"\
            " --input-file #{node['cluster']['cluster_config_path']}  --instance-types-data #{node['cluster']['instance_types_data_path']}"\
            " --compute-node-bootstrap-timeout #{node['cluster']['compute_node_bootstrap_timeout']} #{no_gpu}"
  end
end

# all other OSs use /sys/fs/cgroup, which is the default
template "#{node['cluster']['slurm']['install_dir']}/etc/cgroup.conf" do
  source 'slurm/cgroup.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

template "#{node['cluster']['slurm']['install_dir']}/etc/slurm.sh" do
  source 'slurm/head_node/slurm.sh.erb'
  owner 'root'
  group 'root'
  mode '0755'
end

template "#{node['cluster']['slurm']['install_dir']}/etc/slurm.csh" do
  source 'slurm/head_node/slurm.csh.erb'
  owner 'root'
  group 'root'
  mode '0755'
end

template "#{node['cluster']['scripts_dir']}/slurm/slurm_fleet_status_manager" do
  source 'slurm/fleet_status_manager_program.erb'
  owner node['cluster']['slurm']['user']
  group node['cluster']['slurm']['group']
  mode '0744'
end

file "/var/log/parallelcluster/slurm_fleet_status_manager.log" do
  owner node['cluster']['cluster_admin_user']
  group node['cluster']['cluster_admin_group']
  mode '0640'
end

template "#{node['cluster']['slurm_plugin_dir']}/parallelcluster_slurm_fleet_status_manager.conf" do
  source 'slurm/parallelcluster_slurm_fleet_status_manager.conf.erb'
  owner node['cluster']['cluster_admin_user']
  group node['cluster']['cluster_admin_group']
  mode '0644'
end

template "#{node['cluster']['scripts_dir']}/slurm/slurm_resume" do
  source 'slurm/resume_program.erb'
  owner node['cluster']['slurm']['user']
  group node['cluster']['slurm']['group']
  mode '0744'
end

file "/var/log/parallelcluster/slurm_resume.log" do
  owner node['cluster']['cluster_admin_user']
  group node['cluster']['cluster_admin_group']
  mode '0644'
end

template "#{node['cluster']['slurm_plugin_dir']}/parallelcluster_slurm_resume.conf" do
  source 'slurm/parallelcluster_slurm_resume.conf.erb'
  owner node['cluster']['cluster_admin_user']
  group node['cluster']['cluster_admin_group']
  mode '0644'
end

template "#{node['cluster']['scripts_dir']}/slurm/slurm_suspend" do
  source 'slurm/suspend_program.erb'
  owner node['cluster']['slurm']['user']
  group node['cluster']['slurm']['group']
  mode '0744'
end

file "/var/log/parallelcluster/slurm_suspend.log" do
  owner node['cluster']['cluster_admin_user']
  group node['cluster']['cluster_admin_group']
  mode '0644'
end

template "#{node['cluster']['slurm_plugin_dir']}/parallelcluster_slurm_suspend.conf" do
  source 'slurm/parallelcluster_slurm_suspend.conf.erb'
  owner node['cluster']['cluster_admin_user']
  group node['cluster']['cluster_admin_group']
  mode '0644'
end

template "#{node['cluster']['slurm_plugin_dir']}/parallelcluster_clustermgtd.conf" do
  source 'slurm/parallelcluster_clustermgtd.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

# Create shared directory used to store clustermgtd heartbeat and computemgtd config
directory "#{node['cluster']['slurm']['install_dir']}/etc/pcluster/.slurm_plugin" do
  user node['cluster']['cluster_admin_user']
  group node['cluster']['cluster_admin_group']
  mode '0755'
  action :create
  recursive true
end

# Put computemgtd config under /opt/slurm/etc/pcluster/.slurm_plugin so all compute nodes share a config
template "#{node['cluster']['slurm']['install_dir']}/etc/pcluster/.slurm_plugin/parallelcluster_computemgtd.conf" do
  source 'slurm/parallelcluster_computemgtd.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

cookbook_file '/etc/systemd/system/slurmrestd.service' do
  source 'head_node_slurm/slurmrestd.service'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

template '/etc/systemd/system/slurmctld.service' do
  source 'slurm/head_node/slurmctld.service.erb'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

if node['cluster']['add_node_hostnames_in_hosts_file'] == "true"
  cookbook_file "#{node['cluster']['slurm']['install_dir']}/etc/pcluster/prolog" do
    source 'head_node_slurm/prolog'
    owner node['cluster']['slurm']['user']
    group node['cluster']['slurm']['group']
    mode '0744'
  end

  cookbook_file "#{node['cluster']['slurm']['install_dir']}/etc/pcluster/epilog" do
    source 'head_node_slurm/epilog'
    owner node['cluster']['slurm']['user']
    group node['cluster']['slurm']['group']
    mode '0744'
  end
end

service "slurmctld" do
  supports restart: false
  action %i(enable start)
end
