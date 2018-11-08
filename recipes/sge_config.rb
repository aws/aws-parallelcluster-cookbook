#
# Cookbook Name:: aws-parallelcluster
# Recipe:: sge_config
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

include_recipe 'aws-parallelcluster::base_config'
include_recipe 'aws-parallelcluster::sge_install'

# case node['cfncluster']['cfn_node_type']
case node['cfncluster']['cfn_node_type']
when 'MasterServer'
  include_recipe 'aws-parallelcluster::_master_sge_config'
when 'ComputeFleet'
  include_recipe 'aws-parallelcluster::_compute_sge_config'
else
  raise "cfn_node_type must be MasterServer or ComputeFleet"
end
