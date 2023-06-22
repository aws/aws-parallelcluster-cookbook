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

if node['cluster']['node_type'] == "ComputeFleet"
  volume "mount /home" do
    action :mount
    shared_dir '/home'
    device(lazy { "#{node['cluster']['head_node_private_ip']}:#{node['cluster']['head_node_home_path']}" })
    fstype 'nfs'
    options node['cluster']['nfs']['hard_mount_options']
    retries 10
    retry_delay 6
  end

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
end
