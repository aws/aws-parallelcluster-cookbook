# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-slurm
# Recipe:: finalize_head_node
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
return if on_docker?

execute "check if clustermgtd heartbeat is available" do
  command "cat #{node['cluster']['slurm']['install_dir']}/etc/pcluster/.slurm_plugin/clustermgtd_heartbeat"
  retries 30
  retry_delay 10
end

wait_static_fleet_running

wait_cluster_ready
