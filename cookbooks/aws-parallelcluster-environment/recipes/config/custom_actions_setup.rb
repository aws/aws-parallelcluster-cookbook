# frozen_string_literal: true

#
# Copyright:: 2013-2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

template "#{node['cluster']['scripts_dir']}/fetch_and_run" do
  source 'custom_actions/fetch_and_run.erb'
  owner "root"
  group "root"
  mode "0755"
  variables(
    scheduler: node['cluster']['scheduler'],
    cluster_name: node['cluster']['cluster_name'] || node['cluster']['stack_name'],
    instance_id: node['ec2']['instance_id'],
    instance_type: node['ec2']['instance_type'],
    availability_zone: node['ec2']['availability_zone'],
    ip_address: node['ipaddress'],
    hostname: node['ec2']['hostname'],
    compute_resource: node['cluster']['scheduler_compute_resource_name'],
    # TODO: This needs to be abstracted somehow since this resource should be scheduler independent
    node_spec_file: "#{node['cluster']['slurm_plugin_dir']}/slurm_nodename"
  )
end

cookbook_file "#{node['cluster']['scripts_dir']}/custom_action_executor.py" do
  source 'custom_action_executor/custom_action_executor.py'
  owner 'root'
  group 'root'
  mode '0755'
  action :create_if_missing
end
