#
# Cookbook Name:: cfncluster
# Recipe:: _compute_pbspro_config
#
# Copyright 2013-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Amazon Software License (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/asl/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

execute 'pbs_postinstall' do
  command '/opt/pbs/libexec/pbs_postinstall'
  creates '/etc/pbs.conf'
end

%w{/opt/pbs/sbin/pbs_iff /opt/pbs/sbin/pbs_rcp}.each do |foo|
  file foo do
    mode '4755'
  end
end

template '/etc/pbs.conf' do
  source 'pbs.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

service "pbs" do
  supports restart: true
  action [:enable, :restart]
end

