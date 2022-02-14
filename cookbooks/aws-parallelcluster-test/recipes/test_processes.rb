# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-test
# Recipe:: tests_processes
#
# Copyright:: 2013-2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

###################
# supervisord
###################
check_process_running_as_user("supervisord", "root")

###################
# clustermgtd
###################
if node['cluster']['node_type'] == 'HeadNode' && node['cluster']['scheduler'] == 'slurm'
  user = node['cluster']['cluster_admin_user']
  check_process_running_as_user("clustermgtd", user)
end

###################
# computemgtd
###################
if node['cluster']['node_type'] == 'ComputeNode' && node['cluster']['scheduler'] == 'slurm'
  user = node['cluster']['cluster_admin_user']
  check_process_running_as_user("computemgtd", user)
end
