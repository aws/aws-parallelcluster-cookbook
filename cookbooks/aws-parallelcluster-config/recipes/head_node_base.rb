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

# Setup cluster user and SSH on head node
include_recipe 'aws-parallelcluster-platform::cluster_user'

# generate the shared storages mapping file
include_recipe 'aws-parallelcluster-environment::fs_update'

include_recipe 'aws-parallelcluster-environment::ebs'
include_recipe 'aws-parallelcluster-environment::shared_storages'
include_recipe 'aws-parallelcluster-environment::raid'

include_recipe 'aws-parallelcluster-platform::dcv'

include_recipe 'aws-parallelcluster-computefleet::head_node_fleet_status'
