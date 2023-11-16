# frozen_string_literal: true

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

# Cluster Status Management Daemon
return unless node['cluster']['node_type'] == 'HeadNode' && node['cluster']['scheduler'] != 'awsbatch'

# create placeholder for computefleet-status.json, so it can be written by clusterstatusmgtd which run as pcluster admin user
file node['cluster']['computefleet_status_path'] do
  owner node['cluster']['cluster_admin_user']
  group node['cluster']['cluster_admin_user']
  content '{}'
  mode '0755'
  action :create
end

# create sudoers entry to let pcluster admin user execute update compute fleet recipe
template '/etc/sudoers.d/99-parallelcluster-clusterstatusmgtd' do
  source 'clusterstatusmgtd/99-parallelcluster-clusterstatusmgtd.erb'
  owner 'root'
  group 'root'
  mode '0600'
end

# create log file for clusterstatusmgtd
directory "#{node['cluster']['log_base_dir']}" do
  recursive true
end
file "#{node['cluster']['log_base_dir']}/clusterstatusmgtd" do
  owner 'root'
  group 'root'
  mode '0640'
end
