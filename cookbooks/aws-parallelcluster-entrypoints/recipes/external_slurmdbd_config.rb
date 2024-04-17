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

include_recipe 'aws-parallelcluster-slurm::config_head_node_directories'

include_recipe 'aws-parallelcluster-slurm::external_slurmdbd_disable_unrequired_services'

template "#{node['cluster']['scripts_dir']}/slurm/update_munge_key.sh" do
  cookbook 'aws-parallelcluster-slurm'
  source 'slurm/head_node/update_munge_key.sh.erb'
  owner 'root'
  group 'root'
  mode '0700'
  variables(
    munge_key_secret_arn: lazy { node['munge_key_secret_arn'] }
  )
end

cloudwatch "Configure CloudWatch" do
  action :configure
end

include_recipe 'aws-parallelcluster-slurm::config_munge_key'

include_recipe 'aws-parallelcluster-slurm::retrieve_slurmdbd_config_from_s3'

include_recipe "aws-parallelcluster-slurm::config_slurm_accounting"
