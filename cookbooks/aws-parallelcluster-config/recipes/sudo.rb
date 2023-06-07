# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: sudo
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

# Ensure cluster user can sudo on SSH
template '/etc/sudoers.d/99-parallelcluster-user-tty' do
  source 'base/99-parallelcluster-user-tty.erb'
  owner 'root'
  group 'root'
  mode '0600'
end

# Install parallelcluster specific supervisord config
region = node['cluster']['region']
template "#{node['cluster']['etc_dir']}/parallelcluster_supervisord.conf" do
  source 'base/parallelcluster_supervisord.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    region: region,
    aws_ca_bundle: region.start_with?('us-iso') ? "/etc/pki/#{region}/certs/ca-bundle.pem" : '',
    dcv_configured: node['cluster']['dcv_enabled'] == "head_node" && node['conditions']['dcv_supported']
  )
end
