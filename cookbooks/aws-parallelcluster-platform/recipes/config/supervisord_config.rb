# frozen_string_literal: true

#
# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# Install parallelcluster specific supervisord config
directory node['cluster']['etc_dir']

region = node['cluster']['region']
template "#{node['cluster']['etc_dir']}/parallelcluster_supervisord.conf" do
  source 'supervisord/parallelcluster_supervisord.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    region: region,
    aws_ca_bundle: region.start_with?('us-iso') ? "/etc/pki/#{region}/certs/ca-bundle.pem" : '',
    dcv_configured: node['cluster']['dcv_enabled'] == "head_node" && dcv_installed?,
    dcv_auth_virtualenv_path: node['cluster']['dcv']['authenticator']['virtualenv_path'],
    dcv_auth_user_home: node['cluster']['dcv']['authenticator']['user_home'],
    dcv_port: node['cluster']['dcv_port'],
    dcv_auth_certificate: node['cluster']['dcv']['authenticator']['certificate'],
    dcv_auth_private_key: node['cluster']['dcv']['authenticator']['private_key'],
    dcv_auth_user: node['cluster']['dcv']['authenticator']['user']
  )
end
