# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-slurm
# Recipe:: config_compute
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

template '/etc/systemd/system/check-update.service' do
  source 'check_update/check-update.service.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

cookbook_file '/etc/systemd/system/check-update.timer' do
  source 'check_update/check-update.timer'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

file node['cluster']['shared_update_path'] do
  content ''
  owner 'root'
  group 'root'
  mode '0644'
  action :create_if_missing
end

file node['cluster']['update_checkpoint'] do
  content ''
  owner 'root'
  group 'root'
  mode '0644'
  action :create_if_missing
end

service 'check-update.timer' do
  action [:enable, :start]
end
