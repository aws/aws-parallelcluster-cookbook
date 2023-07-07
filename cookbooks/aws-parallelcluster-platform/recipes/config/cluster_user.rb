# frozen_string_literal: true

#
# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

case node['cluster']['node_type']
when 'HeadNode'
  # Setup cluster user
  user node['cluster']['cluster_user'] do
    manage_home true
    comment 'AWS ParallelCluster user'
    home "/home/#{node['cluster']['cluster_user']}"
    shell '/bin/bash'
  end

  # Setup SSH auth for cluster user
  bash "ssh-keygen" do
    cwd "/home/#{node['cluster']['cluster_user']}"
    code <<-KEYGEN
      set -e
      su - #{node['cluster']['cluster_user']} -c \"ssh-keygen -q -t ed25519 -f ~/.ssh/id_ed25519 -N ''\"
    KEYGEN
    not_if { ::File.exist?("/home/#{node['cluster']['cluster_user']}/.ssh/id_ed25519") }
  end

  bash "copy_and_perms" do
    cwd "/home/#{node['cluster']['cluster_user']}"
    code <<-PERMS
      set -e
      su - #{node['cluster']['cluster_user']} -c \"cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys && chmod 0600 ~/.ssh/authorized_keys && touch ~/.ssh/authorized_keys_cluster\"
    PERMS
    not_if { ::File.exist?("/home/#{node['cluster']['cluster_user']}/.ssh/authorized_keys_cluster") }
  end

  bash "ssh-keyscan" do
    cwd "/home/#{node['cluster']['cluster_user']}"
    code <<-KEYSCAN
      set -e
      su - #{node['cluster']['cluster_user']} -c \"ssh-keyscan #{node['hostname']} > ~/.ssh/known_hosts && chmod 0600 ~/.ssh/known_hosts\"
    KEYSCAN
    not_if { ::File.exist?("/home/#{node['cluster']['cluster_user']}/.ssh/known_hosts") }
  end

when 'ComputeFleet'

  # Setup cluster user
  user node['cluster']['cluster_user'] do
    manage_home false
    comment 'AWS ParallelCluster user'
    home "/home/#{node['cluster']['cluster_user']}"
    shell '/bin/bash'
  end
else
  raise "node_type must be HeadNode or ComputeFleet"
end
