# frozen_string_literal: true

#
# Copyright:: 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

resource_name :fetch_dna_files
provides :fetch_dna_files
unified_mode true

property :extra_chef_attribute_location, String, default: '/tmp/extra.json'

default_action :share

action :share do
  return if on_docker?
  return unless node['cluster']['node_type'] == 'HeadNode'

  Chef::Log.info("Share extra.json with ComputeFleet")
  ::FileUtils.cp_r(new_resource.extra_chef_attribute_location, "#{node['cluster']['shared_dir']}/dna/extra.json", remove_destination: true) if ::File.exist?(new_resource.extra_chef_attribute_location)

  execute "Run share_compute_fleet_dna.py to get user_data.sh and share dna.json with ComputeFleet" do
    command "#{cookbook_virtualenv_path}/bin/python #{node['cluster']['scripts_dir']}/share_compute_fleet_dna.py" \
              " --region #{node['cluster']['region']}"
    timeout 30
    retries 10
    retry_delay 90
  end
end

action :cleanup do
  return if on_docker?
  return unless node['cluster']['node_type'] == 'HeadNode'

  execute "Cleanup dna.json and extra.json from #{node['cluster']['shared_dir']}/dna" do
    command "#{cookbook_virtualenv_path}/bin/python #{node['cluster']['scripts_dir']}/share_compute_fleet_dna.py" \
              " --region #{node['cluster']['region']} --cleanup"
    timeout 30
    retries 10
    retry_delay 90
  end
end
