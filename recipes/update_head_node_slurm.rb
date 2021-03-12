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

updated_cluster_config_path = "/tmp/cluster-config.updated.json"
fetch_config_command = "#{node['cfncluster']['cookbook_virtualenv_path']}/bin/aws s3api get-object"\
                       " --bucket #{node['cfncluster']['cluster_s3_bucket']}"\
                       " --key #{node['cfncluster']['cluster_config_s3_key']}"\
                       " --region #{node['cfncluster']['cfn_region']} #{updated_cluster_config_path}"
fetch_config_command += " --version-id #{node['cfncluster']['cluster_config_version']}" unless node['cfncluster']['cluster_config_version'].nil?
shell_out!(fetch_config_command)
if !File.exist?(node['cfncluster']['cluster_config_path']) || !FileUtils.identical?(updated_cluster_config_path, node['cfncluster']['cluster_config_path'])
  # Generate pcluster specific configs
  execute "generate_pcluster_slurm_configs" do
    command "#{node['cfncluster']['cookbook_virtualenv_path']}/bin/python #{node['cfncluster']['scripts_dir']}/slurm/pcluster_slurm_config_generator.py" \
            " --output-directory /opt/slurm/etc/ --template-directory #{node['cfncluster']['scripts_dir']}/slurm/templates/"\
            " --input-file #{updated_cluster_config_path} --instance-types-data #{node['cfncluster']['instance_types_data_path']}"
  end

  execute 'stop clustermgtd' do
    command "#{node['cfncluster']['cookbook_virtualenv_path']}/bin/supervisorctl stop clustermgtd"
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
    command "#{node['cfncluster']['cookbook_virtualenv_path']}/bin/supervisorctl start clustermgtd"
  end

  execute "copy new config" do
    command "cp #{updated_cluster_config_path} #{node['cfncluster']['cluster_config_path']}"
  end
end

execute 'update cluster config hash in DynamoDB' do
  command "#{node['cfncluster']['cookbook_virtualenv_path']}/bin/aws dynamodb put-item --table-name #{node['cfncluster']['cfn_ddb_table']}"\
          " --item '{\"Id\": {\"S\": \"CLUSTER_CONFIG\"}, \"Version\": {\"S\": \"#{node['cfncluster']['cluster_config_version']}\"}}' --region #{node['cfncluster']['cfn_region']}"
  retries 3
  retry_delay 5
  not_if { node['cfncluster']['cluster_config_version'].nil? }
end
