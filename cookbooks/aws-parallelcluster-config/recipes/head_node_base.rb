# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: head_node_base
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

# generate the shared storages mapping file
include_recipe 'aws-parallelcluster-environment::fs_update'

include_recipe 'aws-parallelcluster-environment::ebs_head_node'

include_recipe 'aws-parallelcluster-environment::shared_storage_head_node'

# Setup RAID array on head node
include_recipe 'aws-parallelcluster-environment::raid'

# Setup cluster user and SSH on head node
include_recipe 'aws-parallelcluster-platform::cluster_user_head_node'


if node['cluster']['dcv_enabled'] == "head_node"
  # Activate DCV on head node
  dcv "Configure DCV" do
    action :configure
  end
end unless on_docker?

include_recipe 'aws-parallelcluster-computefleet::head_node_fleet_status'
