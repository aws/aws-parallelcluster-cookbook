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

# Copy pcluster config generator and templates
include_recipe 'aws-parallelcluster-slurm::config_head_node_directories'

include_recipe 'aws-parallelcluster-slurm::config_check_login_stopped_script'

template "#{node['cluster']['scripts_dir']}/slurm/update_munge_key.sh" do
  source 'slurm/head_node/update_munge_key.sh.erb'
  owner 'root'
  group 'root'
  mode '0700'
  variables(
    munge_key_secret_arn: lazy { node['cluster']['config'].dig(:Scheduling, :SlurmSettings, :MungeKeySecretArn) },
    region: node['cluster']['region'],
    munge_user: node['cluster']['munge']['user'],
    munge_group: node['cluster']['munge']['group'],
    shared_directory_compute: node['cluster']['shared_dir'],
    shared_directory_login: node['cluster']['shared_dir_login_nodes']
  )
end

include_recipe 'aws-parallelcluster-slurm::config_munge_key'

# Export /opt/slurm
nfs_export "#{node['cluster']['slurm']['install_dir']}" do
  network get_vpc_cidr_list
  writeable true
  options ['no_root_squash']
  only_if { node['cluster']['shared_storage_type'] == 'ebs' }
end unless on_docker?

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

unless on_docker?
  # Generate pcluster specific configs
  no_gpu = nvidia_installed? ? "" : "--no-gpu"
  execute "generate_pcluster_slurm_configs" do
    command "#{cookbook_virtualenv_path}/bin/python #{node['cluster']['scripts_dir']}/slurm/pcluster_slurm_config_generator.py"\
            " --output-directory #{node['cluster']['slurm']['install_dir']}/etc/"\
            " --template-directory #{node['cluster']['scripts_dir']}/slurm/templates/"\
            " --input-file #{node['cluster']['cluster_config_path']}"\
            " --instance-types-data #{node['cluster']['instance_types_data_path']}"\
            " --compute-node-bootstrap-timeout #{node['cluster']['compute_node_bootstrap_timeout']} #{no_gpu}"\
            " --realmemory-to-ec2memory-ratio #{node['cluster']['realmemory_to_ec2memory_ratio']}"\
            " --slurmdbd-user #{node['cluster']['slurm']['user']}"\
            " --cluster-name #{node['cluster']['stack_name']}"
  end

  # Generate custom Slurm settings include files
  execute "generate_pcluster_custom_slurm_settings_include_files" do
    command "#{cookbook_virtualenv_path}/bin/python #{node['cluster']['scripts_dir']}/slurm/pcluster_custom_slurm_settings_include_file_generator.py"\
            " --output-directory #{node['cluster']['slurm']['install_dir']}/etc/"\
            " --input-file #{node['cluster']['cluster_config_path']}"
  end

  # If defined in the config, retrieve a remote Custom Slurm Settings file and overrides the existing one
  ruby_block "Override Custom Slurm Settings with remote file" do
    block do
      run_context.include_recipe 'aws-parallelcluster-slurm::retrieve_remote_custom_settings_file'
    end
    not_if { node['cluster']['config'].dig(:Scheduling, :SlurmSettings, :CustomSlurmSettingsIncludeFile).nil? }
  end

  # Generate pcluster fleet config
  execute "generate_pcluster_fleet_config" do
    command "#{cookbook_virtualenv_path}/bin/python #{node['cluster']['scripts_dir']}/slurm/pcluster_fleet_config_generator.py"\
            " --output-file #{node['cluster']['slurm']['fleet_config_path']}"\
            " --input-file #{node['cluster']['cluster_config_path']}"
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

file "/var/log/parallelcluster/clustermgtd.events" do
  owner node['cluster']['cluster_admin_user']
  group node['cluster']['cluster_admin_group']
  mode '0600'
end

file "/var/log/parallelcluster/compute_console_output.log" do
  owner node['cluster']['cluster_admin_user']
  group node['cluster']['cluster_admin_group']
  mode '0600'
end

template "#{node['cluster']['slurm_plugin_dir']}/parallelcluster_slurm_fleet_status_manager.conf" do
  source 'slurm/parallelcluster_slurm_fleet_status_manager.conf.erb'
  owner node['cluster']['cluster_admin_user']
  group node['cluster']['cluster_admin_group']
  mode '0644'
end

include_recipe 'aws-parallelcluster-slurm::config_slurm_resume'

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
end unless on_docker?

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

template '/etc/systemd/system/slurmctld.service' do
  source 'slurm/head_node/slurmctld.service.erb'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

include_recipe 'aws-parallelcluster-slurm::config_health_check'

ruby_block "Configure Slurm Accounting" do
  block do
    run_context.include_recipe "aws-parallelcluster-slurm::config_slurm_accounting"
  end
  not_if { node['cluster']['config'].dig(:Scheduling, :SlurmSettings, :Database).nil? }
end unless on_docker?

service "slurmctld" do
  supports restart: false
  action %i(enable start)
end unless on_docker?

# The slurmctld service does not return an error code to `systemctl start slurmctld`, so
# we must explicitly check the status of the service to capture failures
chef_sleep 3

execute "check slurmctld status" do
  command "systemctl is-active --quiet slurmctld.service"
  retries 5
  retry_delay 2
end unless redhat_on_docker?
