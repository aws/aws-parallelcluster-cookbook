# frozen_string_literal: true

#
# Copyright:: 2024 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

cloudformation_url = "https://cloudformation.#{node['cluster']['region']}.#{node['cluster']['aws_domain']}"
instance_role_name = lambda {
  # IMDS is not available on Docker
  return "FAKE_INSTANCE_ROLE_NAME" if on_docker?
  get_metadata_with_token(get_metadata_token, URI("http://169.254.169.254/latest/meta-data/iam/security-credentials"))
}.call

directory '/etc/cfn' do
  owner 'root'
  group 'root'
  mode '0770'
  recursive true
end

directory '/etc/cfn/hooks.d' do
  owner 'root'
  group 'root'
  mode '0770'
  recursive true
end

template '/etc/cfn/cfn-hup.conf' do
  source 'cfn_bootstrap/cfn-hup.conf.erb'
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

case node['cluster']['node_type']
when 'HeadNode', 'LoginNode'
  template '/etc/cfn/hooks.d/pcluster-update.conf' do
    source 'cfn_bootstrap/cfn-hook-update.conf.erb'
    owner 'root'
    group 'root'
    mode '0400'
    variables(
      stack_id: node['cluster']['stack_arn'],
      region: node['cluster']['region'],
      cloudformation_url: cloudformation_url,
      cfn_init_role: instance_role_name,
      launch_template_resource_id: node['cluster']['launch_template_id']
    )
  end

when 'ComputeFleet'
  template "#{node['cluster']['scripts_dir']}/cfn-hup-update-compute-action.sh" do
    source "cfn_bootstrap/cfn-hup-update-compute-action.sh.erb"
    owner 'root'
    group 'root'
    mode '0744'
    variables(
      clusterS3Bucket: node['cluster']['cluster_s3_bucket'],
      region: node['cluster']['region'],
      clusterS3ArtifactDir: node['cluster']['cluster_config_s3_key'].chomp('/configs/cluster-config-with-implied-values.yaml'),
      clusterConfigVersion: node['cluster']['cluster_config_version'],
      launch_template_resource_id: node['cluster']['launch_template_id']
    )
  end
  
  
  template '/etc/cfn/hooks.d/pcluster-update.conf' do
    source 'cfn_bootstrap/cfn-hook-update-compute.conf.erb'
    owner 'root'
    group 'root'
    mode '0400'
    variables(
      launch_template_resource_id: node['cluster']['launch_template_id']
    )
  end
end
