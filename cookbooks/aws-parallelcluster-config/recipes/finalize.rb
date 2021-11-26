# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-config
# Recipe:: finalize
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

fetch_config 'Fetch and load cluster configs' unless node['cluster']['scheduler'] == 'awsbatch'

# Restart supervisord
service "supervisord" do
  supports restart: true
  action %i(enable start)
end

include_recipe 'aws-parallelcluster-scheduler-plugin::finalize' if node['cluster']['scheduler'] == 'plugin'
include_recipe 'aws-parallelcluster-slurm::finalize' if node['cluster']['scheduler'] == 'slurm'
