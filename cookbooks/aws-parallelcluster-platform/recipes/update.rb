# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-platform
# Recipe:: update
#
# Copyright:: 2013-2024 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

manage_dna_files "Fetch ComputeFleet's and LoginFleets's Dna files" do
  action :share
end
fetch_config 'Fetch and load cluster configs' do
  update true
end

sudo_access "Update Sudo Access"
include_recipe 'aws-parallelcluster-platform::config_login' if node['cluster']['node_type'] == 'LoginNode'
