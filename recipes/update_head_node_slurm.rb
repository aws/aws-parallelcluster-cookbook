# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: update_head_node_slurm
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

updated_cluster_config_path = "/tmp/cluster-config.updated.yaml"
fetch_config_command = "#{node['cluster']['cookbook_virtualenv_path']}/bin/aws s3api get-object"\
                       " --bucket #{node['cluster']['cluster_s3_bucket']}"\
                       " --key #{node['cluster']['cluster_config_s3_key']}"\
                       " --region #{node['cluster']['region']} #{updated_cluster_config_path}"
fetch_config_command += " --version-id #{node['cluster']['cluster_config_version']}" unless node['cluster']['cluster_config_version'].nil?
shell_out!(fetch_config_command)
if !File.exist?(node['cluster']['cluster_config_path']) || !FileUtils.identical?(updated_cluster_config_path, node['cluster']['cluster_config_path'])
  # Copy instance type infos file from S3 URI
  fetch_config_command = "#{node['cluster']['cookbook_virtualenv_path']}/bin/aws s3api get-object --bucket #{node['cluster']['cluster_s3_bucket']}"\
                       " --key #{node['cluster']['instance_types_data_s3_key']} --region #{node['cluster']['region']} #{node['cluster']['instance_types_data_path']}"
  execute "copy_instance_type_data_from_s3" do
    command fetch_config_command
    retries 3
    retry_delay 5
  end
  # Generate pcluster specific configs
  execute "generate_pcluster_slurm_configs" do
    command "#{node['cluster']['cookbook_virtualenv_path']}/bin/python #{node['cluster']['scripts_dir']}/slurm/pcluster_slurm_config_generator.py" \
            " --output-directory /opt/slurm/etc/ --template-directory #{node['cluster']['scripts_dir']}/slurm/templates/"\
            " --input-file #{updated_cluster_config_path} --instance-types-data #{node['cluster']['instance_types_data_path']}"
  end

  execute 'stop clustermgtd' do
    command "#{node['cluster']['cookbook_virtualenv_path']}/bin/supervisorctl stop clustermgtd"
  end

  slurmctld_service = node['init_package'] == 'systemd' ? "slurmctld" : "slurm"
  service slurmctld_service do
    action :restart
  end

  execute 'reload config for running nodes' do
    command "/opt/slurm/bin/scontrol reconfigure && sleep 15"
    retries 3
    retry_delay 5
  end

  execute 'start clustermgtd' do
    command "#{node['cluster']['cookbook_virtualenv_path']}/bin/supervisorctl start clustermgtd"
  end

  execute "copy new config" do
    command "cp #{updated_cluster_config_path} #{node['cluster']['cluster_config_path']}"
  end
end

execute 'update cluster config hash in DynamoDB' do
  command "#{node['cluster']['cookbook_virtualenv_path']}/bin/aws dynamodb put-item --table-name #{node['cluster']['ddb_table']}"\
          " --item '{\"Id\": {\"S\": \"CLUSTER_CONFIG_WITH_IMPLIED_VALUES\"}, \"Version\": {\"S\": \"#{node['cluster']['cluster_config_version']}\"}}' --region #{node['cluster']['region']}"
  retries 3
  retry_delay 5
  not_if { node['cluster']['cluster_config_version'].nil? }
end
