#
# Cookbook:: aws-parallelcluster
# Recipe:: users
#
# Copyright:: 2013-2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# Setup cluster admin group
group node['cluster']['cluster_admin_group'] do
  comment 'AWS ParallelCluster Admin group'
  gid node['cluster']['cluster_admin_group_id']
  system true
end

# Setup cluster admin user
user node['cluster']['cluster_admin_user'] do
  comment 'AWS ParallelCluster Admin user'
  uid node['cluster']['cluster_admin_user_id']
  gid node['cluster']['cluster_admin_group_id']
  system true
  shell '/bin/bash'
  home "/home/#{node['cluster']['cluster_admin_user']}"
  manage_home false
end

# Calling user_ulimit will override every existing limit
user_ulimit "*" do
  filehandle_limit node['cluster']['filehandle_limit']
end
