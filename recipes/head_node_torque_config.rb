# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: head_node_torque_config
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

setup_munge_head_node

# Modified torque.setup
template 'torque.setup' do
  source 'torque.setup.erb'
  path '/opt/torque/bin/torque.setup'
  user 'root'
  group 'root'
  mode '0755'
end

# Run torque.setup
bash "run-torque-setup" do
  code <<-SETUPTORQUE
    set -e
    . /etc/profile.d/torque.sh
    ./torque.setup root
  SETUPTORQUE
  cwd '/opt/torque/bin'
end

# Copy pbs_server service script
remote_file "install pbs_server service" do
  path "/etc/init.d/pbs_server"
  source node['cfncluster']['torque']['pbs_server_source']
  owner 'root'
  group 'root'
  mode 0755
end

# Enable and start munge service
service "munge" do
  supports restart: true
  action %i[enable start]
end

# Enable and start pbs_server service
service "pbs_server" do
  supports restart: true
  action %i[enable restart]
end

# Copy pbs_sched service script
remote_file "install pbs_sched service" do
  path "/etc/init.d/pbs_sched"
  source node['cfncluster']['torque']['pbs_sched_source']
  owner 'root'
  group 'root'
  mode 0755
end

# Enable and start pbs_sched service
service "pbs_sched" do
  supports restart: true
  action %i[enable start]
end
