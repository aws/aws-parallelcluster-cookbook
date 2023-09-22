# frozen_string_literal: true

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

return if on_docker?

case node['cluster']['node_type']
when 'ComputeFleet'
  include_recipe 'aws-parallelcluster-environment::mount_home'

  # Mount /opt/parallelcluster/shared over NFS
  volume "mount #{node['cluster']['shared_dir_compute']}" do
    action :mount
    shared_dir node['cluster']['shared_dir_compute']
    device(lazy { "#{node['cluster']['head_node_private_ip']}:#{node['cluster']['shared_dir_head']}" })
    fstype 'nfs'
    options node['cluster']['nfs']['hard_mount_options']
    retries 10
    retry_delay 6
  end

when 'LoginNode'
  include_recipe 'aws-parallelcluster-environment::mount_home'

  # Mount /opt/parallelcluster/shared_login_nodes over NFS
  volume "mount #{node['cluster']['shared_dir_login']}" do
    action :mount
    shared_dir node['cluster']['shared_dir_login']
    device(lazy { "#{node['cluster']['head_node_private_ip']}:#{node['cluster']['shared_dir_login']}" })
    fstype 'nfs'
    options node['cluster']['nfs']['hard_mount_options']
    retries 10
    retry_delay 6
  end
when 'HeadNode'
  Chef::Log.info("Nothing to mount in the HeadNode")
else
  raise "node_type must be HeadNode, LoginNode or ComputeFleet"
end
