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

provides :cfn_hup_configuration
unified_mode true
default_action :configure

action :configure do
  cloudformation_url = "https://cloudformation.#{node['cluster']['region']}.#{node['cluster']['aws_domain']}"
  instance_role_name = lambda {
    # IMDS is not available on Docker
    return "FAKE_INSTANCE_ROLE_NAME" if on_docker?
    get_metadata_with_token(get_metadata_token, URI("http://169.254.169.254/latest/meta-data/iam/security-credentials"))
  }.call

  directory '/etc/cfn' do
    owner 'root'
    group 'root'
    mode '0700'
    recursive true
  end

  directory '/etc/cfn/hooks.d' do
    owner 'root'
    group 'root'
    mode '0700'
    recursive true
  end

  template '/etc/cfn/cfn-hup.conf' do
    source 'cfn_hup_configuration/cfn-hup.conf.erb'
    owner 'root'
    group 'root'
    mode '0400'
    variables(
      stack_id: node['cluster']['stack_arn'],
      region: node['cluster']['region'],
      cloudformation_url: cloudformation_url,
      cfn_init_role: instance_role_name
    )
  end

  action_extra_configuration

  template '/etc/cfn/hooks.d/pcluster-update.conf' do
    source "cfn_hup_configuration/cfn-hook-update.conf.erb"
    owner 'root'
    group 'root'
    mode '0400'
    variables(
      stack_id: node['cluster']['stack_arn'],
      region: node['cluster']['region'],
      cloudformation_url: cloudformation_url,
      cfn_init_role: instance_role_name,
      launch_template_resource_id: node['cluster']['launch_template_id'],
      update_hook_script_dir: node['cluster']['scripts_dir'],
      node_bootstrap_timeout: node['cluster']['compute_node_bootstrap_timeout'] || node['cluster']['Timeout']
    )
  end
end

action :extra_configuration do
  case node['cluster']['node_type']
  when 'HeadNode'
    cookbook_file "#{node['cluster']['scripts_dir']}/share_compute_fleet_dna.py" do
      source 'cfn_hup_configuration/share_compute_fleet_dna.py'
      owner 'root'
      group 'root'
      mode '0700'
      action :create_if_missing
    end

    directory "#{node['cluster']['shared_dir']}/dna"

  when 'ComputeFleet'
    template "#{node['cluster']['scripts_dir']}/cfn-hup-update-action.sh" do
      source "cfn_hup_configuration/#{node['cluster']['node_type']}/cfn-hup-update-action.sh.erb"
      owner 'root'
      group 'root'
      mode '0700'
      variables(
        monitor_shared_dir: monitor_shared_dir,
        launch_template_resource_id: node['cluster']['launch_template_id']
      )
    end
  end
end

action_class do
  def monitor_shared_dir
    "#{node['cluster']['shared_dir']}/dna"
  end
end
