# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-slurm
# Recipe:: update_head_node
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

execute "generate_pcluster_slurm_configs" do
  command "#{node['cluster']['cookbook_virtualenv_path']}/bin/python #{node['cluster']['scripts_dir']}/slurm/pcluster_slurm_config_generator.py" \
          " --output-directory /opt/slurm/etc/" \
          " --template-directory #{node['cluster']['scripts_dir']}/slurm/templates/" \
          " --input-file #{node['cluster']['cluster_config_path']}" \
          " --instance-types-data #{node['cluster']['instance_types_data_path']}" \
          " --compute-node-bootstrap-timeout #{node['cluster']['compute_node_bootstrap_timeout']}" \
          " #{nvidia_installed? ? '' : '--no-gpu'}"
  not_if { ::File.exist?(node['cluster']['previous_cluster_config_path']) && !are_queues_updated? }
end

execute 'stop clustermgtd' do
  command "#{node['cluster']['cookbook_virtualenv_path']}/bin/supervisorctl stop clustermgtd"
  not_if { ::File.exist?(node['cluster']['previous_cluster_config_path']) && !are_queues_updated? }
end

replace_or_add "update node replacement timeout" do
  path "/etc/parallelcluster/slurm_plugin/parallelcluster_clustermgtd.conf"
  pattern "node_replacement_timeout*"
  line "node_replacement_timeout = #{node['cluster']['compute_node_bootstrap_timeout']}"
  replace_only true
end

service 'slurmctld' do
  action :restart
  not_if { ::File.exist?(node['cluster']['previous_cluster_config_path']) && !are_queues_updated? }
end

execute 'reload config for running nodes' do
  command "/opt/slurm/bin/scontrol reconfigure && sleep 15"
  retries 3
  retry_delay 5
  not_if { ::File.exist?(node['cluster']['previous_cluster_config_path']) && !are_queues_updated? }
end

execute 'start clustermgtd' do
  command "#{node['cluster']['cookbook_virtualenv_path']}/bin/supervisorctl start clustermgtd"
  not_if { ::File.exist?(node['cluster']['previous_cluster_config_path']) && !are_queues_updated? }
end
