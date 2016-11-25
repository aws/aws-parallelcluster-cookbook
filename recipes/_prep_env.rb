#
# Cookbook Name:: cfncluster
# Recipe:: _prep_env
#
# Copyright 2013-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# Determine cfn_scheduler_slots settings and update cfn_instance_slots appropriately
node.default['cfncluster']['cfn_instance_slots'] = if node['cfncluster']['cfn_scheduler_slots'] == 'vcpus'
                                                     node['cpu']['total']
                                                   elsif node['cfncluster']['cfn_scheduler_slots'] == 'cores'
                                                     node['cpu']['total'] / 2
                                                   else
                                                     node['cfncluster']['cfn_scheduler_slots']
                                                   end

directory '/etc/cfncluster'
directory '/opt/cfncluster'
directory '/opt/cfncluster/scripts'

template '/etc/cfncluster/cfnconfig' do
  source 'cfnconfig.erb'
  mode '0644'
end

link '/opt/cfncluster/cfnconfig' do
  to '/etc/cfncluster/cfnconfig'
end

cookbook_file "fetch_and_run" do
  path "/opt/cfncluster/scripts/fetch_and_run"
  owner "root"
  group "root"
  mode "0755"
end

cookbook_file "compute_ready" do
  path "/opt/cfncluster/scripts/compute_ready"
  owner "root"
  group "root"
  mode "0755"
end
