#
# Cookbook Name:: cfncluster
# Recipe:: _compute_torque_config
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

# pbs_mom config
template '/var/spool/torque/mom_priv/config' do
  source 'torque.config.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

# Copy pbs_mom service script
remote_file "install pbs_mom service" do
  path "/etc/init.d/pbs_mom"
  source node['cfncluster']['torque']['pbs_mom_source']
  owner 'root'
  group 'root'
  mode 0755
end

# Enable and start pbs_mom service
service "pbs_mom" do
  supports restart: true
  action %i[enable restart]
end
