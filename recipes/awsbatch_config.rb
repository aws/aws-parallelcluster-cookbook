# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: aws_batch_config
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

# Use these recipes to add a custom scheduler
include_recipe 'aws-parallelcluster::base_config'
include_recipe 'aws-parallelcluster::awsbatch_install'

# Install aws-parallelcluster-awsbatch-cli.cfg
awsbatch_cli_config_dir = "/home/#{node['cluster']['cluster_user']}/.parallelcluster/"

directory awsbatch_cli_config_dir do
  owner node['cluster']['cluster_user']
  group node['cluster']['cluster_user']
  recursive true
end

template "#{awsbatch_cli_config_dir}/awsbatch-cli.cfg" do
  source 'awsbatch-cli.cfg.erb'
  owner node['cluster']['cluster_user']
  group node['cluster']['cluster_user']
  mode '0644'
end
