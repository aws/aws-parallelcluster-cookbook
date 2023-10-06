# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-slurm
# Recipe:: config_slurm_resume
#
# Copyright:: 2013-2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

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

file "/var/log/parallelcluster/slurm_resume.events" do
  owner node['cluster']['cluster_admin_user']
  group node['cluster']['cluster_admin_group']
  mode '0644'
end

template "#{node['cluster']['slurm_plugin_dir']}/parallelcluster_slurm_resume.conf" do
  source 'slurm/parallelcluster_slurm_resume.conf.erb'
  owner node['cluster']['cluster_admin_user']
  group node['cluster']['cluster_admin_group']
  mode '0644'
  variables(
    cluster_name: node['cluster']['stack_name'],
    region: node['cluster']['region'],
    proxy: node['cluster']['proxy'],
    dynamodb_table: node['cluster']['slurm_ddb_table'],
    hosted_zone: node['cluster']['hosted_zone'],
    dns_domain: node['cluster']['dns_domain'],
    use_private_hostname: node['cluster']['use_private_hostname'],
    head_node_private_ip: on_docker? ? 'local_ipv4' : node['ec2']['local_ipv4'],
    head_node_hostname: on_docker? ? 'local_hostname' : node['ec2']['local_hostname'],
    clustermgtd_heartbeat_file_path: "#{node['cluster']['slurm']['install_dir']}/etc/pcluster/.slurm_plugin/clustermgtd_heartbeat",
    instance_id: on_docker? ? 'instance_id' : node['ec2']['instance_id'],
    scaling_strategy: node['cluster']['config'].dig(:Scheduling, :ScalingStrategy)
  )
end
