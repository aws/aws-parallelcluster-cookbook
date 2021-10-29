# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster-config
# Recipe:: fetch_config
#
# Copyright 2013-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

unless virtualized?
  # Copy cluster config file from S3 URI
  fetch_config_command = "#{node['cluster']['cookbook_virtualenv_path']}/bin/aws s3api get-object"\
                         " --bucket #{node['cluster']['cluster_s3_bucket']}"\
                         " --key #{node['cluster']['cluster_config_s3_key']}"\
                         " --region #{node['cluster']['region']}"\
                         " #{node['cluster']['cluster_config_path']}"
  fetch_config_command += " --version-id #{node['cluster']['cluster_config_version']}" unless node['cluster']['cluster_config_version'].nil?
  execute "copy_cluster_config_from_s3" do
    command fetch_config_command
    retries 3
    retry_delay 5
    not_if { ::File.exist?(node['cluster']['cluster_config_path']) }
  end

  # load cluster config into node object
  load_cluster_config

  # Copy instance type infos file from S3 URI
  fetch_config_command = "#{node['cluster']['cookbook_virtualenv_path']}/bin/aws s3api get-object"\
                         " --bucket #{node['cluster']['cluster_s3_bucket']}"\
                         " --key #{node['cluster']['instance_types_data_s3_key']}"\
                         " --region #{node['cluster']['region']}"\
                         " #{node['cluster']['instance_types_data_path']}"
  execute "copy_instance_type_data_from_s3" do
    command fetch_config_command
    retries 3
    retry_delay 5
    not_if { ::File.exist?(node['cluster']['instance_types_data_path']) }
  end
end
