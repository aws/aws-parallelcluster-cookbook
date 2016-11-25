#
# Cookbook Name:: cfncluster
# Recipe:: _master_openlava_config
#
# Copyright 2013-2015 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# Openlava config files
template '/opt/openlava/etc/lsf.conf' do
  source 'lsf.conf.erb'
  owner 'openlava'
  group 'openlava'
  mode '0644'
end

template '/opt/openlava/etc/lsf.cluster.openlava' do
  source 'lsf.cluster.openlava.erb'
  owner 'openlava'
  group 'openlava'
  mode '0644'
end

template '/opt/openlava/etc/lsb.hosts' do
  source 'lsb.hosts.erb'
  owner 'openlava'
  group 'openlava'
  mode '0644'
end

template '/opt/openlava/etc/lsf.shared' do
  source 'lsf.shared.erb'
  owner 'openlava'
  group 'openlava'
  mode '0644'
end

template '/opt/cfncluster/scripts/publish_pending' do
  source 'publish_pending.openlava.erb'
  owner 'root'
  group 'root'
  mode '0744'
end

cookbook_file 'openlava-init' do
  path '/etc/init.d/openlava'
  user 'root'
  group 'root'
  mode '0755'
end

service "openlava" do
  supports status: true, restart: true, reload: true
  action [:enable, :start]
end

execute "badmin hclose" do
  environment 'LSF_ENVDIR' => '/opt/openlava/etc'
  command '/opt/openlava/bin/badmin hclose'
end

cron 'publish_pending' do
  command '/opt/cfncluster/scripts/publish_pending'
end
