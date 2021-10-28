# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster-config
# Recipe:: finalize
#
# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

include_recipe "aws-parallelcluster-config::fetch_config" unless node['cluster']['scheduler'] == 'awsbastch'

# Restart supervisord
service "supervisord" do
  supports restart: true
  action %i[enable start]
end

include_recipe 'aws-parallelcluster-byos::config_finalize' if node['cluster']['scheduler'] == 'byos'

case node['cluster']['node_type']
when 'HeadNode'
  include_recipe 'aws-parallelcluster-slurm::head_node_finalize' if node['cluster']['scheduler'] == 'slurm'
when 'ComputeFleet'
  include_recipe 'aws-parallelcluster-slurm::compute_finalize' if node['cluster']['scheduler'] == 'slurm'
end
