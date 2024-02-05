# frozen_string_literal: true

#
# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# Mock necessary attributes to reuse the recipes from ParallelCluster.
node.default['cluster']['slurm']['install_dir'] = '/opt/slurm'
node.default['cluster']['slurm']['user'] = 'slurm'
node.default['cluster']['slurm']['group'] = 'slurm'
node.default['cluster']['scripts_dir'] = '/opt/parallelcluster/scripts'
node.default['cluster']['region'] = node['region']
node.default['cluster']['slurmdbd_response_retries'] = 30
node.default['cluster']['stack_name'] = node['stack_name']
node.default['cluster']['munge']['user'] = 'munge'
node.default['cluster']['munge']['group'] = node['cluster']['munge']['user']
node.default['cluster']['node_type'] = 'ExternalSlurmDbd' # force node_type to ExternalSlurmDbd to configure CW agent
node.default['cluster']['cw_logging_enabled'] = 'true' # enable CW agent logging
node.default['cluster']['log_group_name'] = node['log_group_name'] # map the `log_group_name` coming from the dna.json to the proper variable expected by the recipes

# rubocop:disable Lint/DuplicateBranch
if platform?('amazon') && node['platform_version'] == "2"
  node.default['cluster']['cluster_user'] = 'ec2-user'
elsif platform?('centos') && node['platform_version'].to_i == 7
  node.default['cluster']['cluster_user'] = 'centos'
elsif platform?('redhat')
  node.default['cluster']['cluster_user'] = 'ec2-user'
elsif platform?('rocky')
  node.default['cluster']['cluster_user'] = 'rocky'
elsif platform?('ubuntu')
  node.default['cluster']['cluster_user'] = 'ubuntu'
end
# rubocop:enable Lint/DuplicateBranch

include_recipe 'aws-parallelcluster-slurm::config_head_node_directories'

include_recipe 'aws-parallelcluster-slurm::external_slurmdbd_disable_unrequired_services'

# TODO: move this template to a separate recipe
# TODO: add a logic in update_munge_key.sh.erb to skip sharing munge key to shared dir
template "#{node['cluster']['scripts_dir']}/slurm/update_munge_key.sh" do
  cookbook 'aws-parallelcluster-slurm'
  source 'slurm/head_node/update_munge_key.sh.erb'
  owner 'root'
  group 'root'
  mode '0700'
  variables(
    munge_key_secret_arn: lazy { node['munge_key_secret_arn'] || node['cluster']['config'].dig(:Scheduling, :SlurmSettings, :MungeKeySecretArn) },
    region: node['cluster']['region'],
    munge_user: node['cluster']['munge']['user'],
    munge_group: node['cluster']['munge']['group'],
    # TODO: modify these two shared_directory
    shared_directory_compute: node['cluster']['shared_dir'],
    shared_directory_login: node['cluster']['shared_dir_login_nodes']
  )
end

cloudwatch "Configure CloudWatch" do
  action :configure
end

# TODO: add a logic in munge_key_manager to skip sharing munge key to shared dir
include_recipe 'aws-parallelcluster-slurm::config_munge_key'

include_recipe 'aws-parallelcluster-slurm::retrieve_slurmdbd_config_from_s3'

include_recipe "aws-parallelcluster-slurm::config_slurm_accounting"
