# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-slurm
# Recipe:: config_head_node
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

# Overrides destination while testing since remote_file expect the destination path to already exist
# To keep the test dependencies at the minimum we use /tmp as destination
local_path = if kitchen_test?
               node['cluster']['config'].dig(:Scheduling, :SlurmSettings, :LocalPath)
             else
               "#{node['cluster']['slurm']['install_dir']}/etc/pcluster/custom_slurm_settings_include_file_slurm.conf"
             end

remote_object 'Retrieve Custom Slurm Settings' do
  url(lazy { node['cluster']['config'].dig(:Scheduling, :SlurmSettings, :CustomSlurmSettingsIncludeFile) })
  destination local_path
  sensitive true
end
