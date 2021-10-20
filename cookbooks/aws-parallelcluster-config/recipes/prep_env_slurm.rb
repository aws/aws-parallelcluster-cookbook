# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: prep_env_slurm
#
# Copyright 2013-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# Ensure slurm plugin directory is in place
# Directory will contain slurm_nodename file used to identify current compute node in computemgtd
directory node['cluster']['slurm_plugin_dir'] do
  user 'root'
  group 'root'
  mode '0755'
  action :create
  recursive true
end

# Retrieve compute info from dynamodb and save into file
if node['cluster']['node_type'] == "ComputeFleet"

  ruby_block "retrieve compute node info" do
    block do
      slurm_nodename = hit_dynamodb_info
      node.force_default['cluster']['slurm_nodename'] = slurm_nodename
    end
    retries 5
    retry_delay 3
    not_if do
      !node['cluster']['slurm_nodename'].nil? && !node['cluster']['slurm_nodename'].empty?
    end
  end

  file "#{node['cluster']['slurm_plugin_dir']}/slurm_nodename" do # ~FC005
    content(lazy { node['cluster']['slurm_nodename'] })
    mode '0644'
    owner 'root'
    group 'root'
  end
end
