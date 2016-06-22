#
# Cookbook Name:: cfnclustr
# Recipe:: pbspro_config
#
# Copyright 2013-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Amazon Software License (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/asl/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

include_recipe 'cfncluster::base_config'

# Only builds on RHEL based systems at this time
if node['platform_family'] == 'rhel'

include_recipe 'cfncluster::pbspro_install'

# case node['cfncluster']['cfn_node_type']
case node['cfncluster']['cfn_node_type']
when 'MasterServer'
  include_recipe 'cfncluster::_master_pbspro_config'
when 'ComputeFleet'
  include_recipe 'cfncluster::_compute_pbspro_config'
else
  raise "cfn_node_type must be MasterServer or ComputeFleet"
end

end
