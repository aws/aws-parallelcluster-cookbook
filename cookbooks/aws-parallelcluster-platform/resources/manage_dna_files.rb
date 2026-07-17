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

resource_name :manage_dna_files
provides :manage_dna_files
unified_mode true

property :extra_chef_attribute_location, String, default: lazy { "#{node['cluster']['exec_tmp_dir']}/extra.json" }

default_action :share

action :share do
  return if on_docker?
  return unless node['cluster']['node_type'] == 'HeadNode'

  Chef::Log.info("Share extra.json with ComputeFleet and LoginNodes")
  ::FileUtils.cp_r(new_resource.extra_chef_attribute_location, "#{node['cluster']['update']['dna_dir']}/extra.json", remove_destination: true) if ::File.exist?(new_resource.extra_chef_attribute_location)

  # Wait for LoginNodes nested stack to publish the new LT version before fetching.
  # The head-node update workflow runs in parallel with the LoginNodes nested stack update;
  # we poll until login pool LTs have the expected cluster_config_version in their UserData.
  execute "Wait for login nodes LT to have the expected cluster_config_version" do
    command "#{cookbook_virtualenv_path}/bin/python #{node['cluster']['scripts_dir']}/manage_fleet_dna.py" \
              " --region #{node['cluster']['region']}" \
              " --wait-login-nodes-launch-template-config-version #{node['cluster']['cluster_config_version']}"
    timeout 30
    retries 10
    retry_delay 30
    only_if { login_nodes_enabled? }
  end

  execute "Run manage_fleet_dna.py to get user_data.sh and share dna.json with ComputeFleet and LoginNodes" do
    command "#{cookbook_virtualenv_path}/bin/python #{node['cluster']['scripts_dir']}/manage_fleet_dna.py" \
              " --region #{node['cluster']['region']}"
    timeout 30
    retries 10
    retry_delay 90
  end
end

action :cleanup do
  return if on_docker?
  return unless node['cluster']['node_type'] == 'HeadNode'

  execute "Cleanup dna.json and extra.json from #{node['cluster']['update']['dna_dir']}" do
    command "#{cookbook_virtualenv_path}/bin/python #{node['cluster']['scripts_dir']}/manage_fleet_dna.py" \
              " --region #{node['cluster']['region']} --cleanup"
    timeout 30
    retries 10
    retry_delay 90
  end
end
