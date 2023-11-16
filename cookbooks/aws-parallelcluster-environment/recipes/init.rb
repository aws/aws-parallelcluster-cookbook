# frozen_string_literal: true

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
#

include_recipe "aws-parallelcluster-environment::cfnconfig_mixed"
cloudwatch "Configure CloudWatch" do
  action :configure
end

case node['cluster']['internal_shared_storage_type']
when 'efs'
  include_recipe "aws-parallelcluster-environment::mount_internal_use_efs"
when 'ebs'
  include_recipe "aws-parallelcluster-environment::mount_internal_use_ebs"
else
  raise "internal_shared_storage_type must be ebs or efs"
end

# Mount the home directory to all nodes if it is shared, otherwise mount the NFS share to compute and login nodes
include_recipe "aws-parallelcluster-environment::mount_home"

include_recipe "aws-parallelcluster-environment::network_interfaces"
include_recipe 'aws-parallelcluster-environment::imds'

# login nodes keys and directory service require shared storage
include_recipe "aws-parallelcluster-environment::login_nodes_keys"
include_recipe "aws-parallelcluster-environment::directory_service"

# Custom action setup must be executed after cfnconfig file creation
include_recipe "aws-parallelcluster-environment::custom_actions_setup"
