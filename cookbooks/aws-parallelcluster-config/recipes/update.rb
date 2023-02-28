# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-config
# Recipe:: update
#
# Copyright:: 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

fetch_config 'Fetch and load cluster configs' do
  update true
end

# generate the update shared storages mapping file
include_recipe 'aws-parallelcluster-config::fs_update'

include_recipe 'aws-parallelcluster-config::directory_service'
include_recipe 'aws-parallelcluster-slurm::update' if node['cluster']['scheduler'] == 'slurm'
include_recipe 'aws-parallelcluster-scheduler-plugin::update' if node['cluster']['scheduler'] == 'plugin'

# Update node package - useful for development purposes only
if !node['cluster']['custom_node_package'].nil? && !node['cluster']['custom_node_package'].empty?

  execute 'stop clustermgtd' do
    command "#{node['cluster']['cookbook_virtualenv_path']}/bin/supervisorctl stop clustermgtd"
  end

  include_recipe 'aws-parallelcluster-install::custom_parallelcluster_node'

  execute 'start clustermgtd' do
    command "#{node['cluster']['cookbook_virtualenv_path']}/bin/supervisorctl start clustermgtd"
  end

end
