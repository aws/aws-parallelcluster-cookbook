# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-config
# Recipe:: cfnconfig_mixed
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

# Determine scheduler_slots settings and update instance_slots appropriately
node.default['cluster']['instance_slots'] = case node['cluster']['scheduler_slots']
                                            when 'vcpus'
                                              node['cpu']['total']
                                            when 'cores'
                                              node['cpu']['cores']
                                            else
                                              node['cluster']['scheduler_slots']
                                            end

template "#{node['cluster']['etc_dir']}/cfnconfig" do
  source 'init/cfnconfig.erb'
  mode '0644'
end

link "#{node['cluster']['base_dir']}/cfnconfig" do
  to "#{node['cluster']['etc_dir']}/cfnconfig"
end unless on_docker?
