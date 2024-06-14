# frozen_string_literal: true

#
# Copyright:: 2024 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

return if node['cluster']['default_user_home'] == 'shared'

# Stop sshd and close all connections
service 'sshd' do
  action :stop
  sensitive true
end
bash "Close ssh connections to perform a default user move" do
  user 'root'
  group 'root'
  returns [0, 1]
  code <<-EOH
    pkill --signal HUP sshd
  EOH
end

# Backup the cluster user's default home directory
bash "Backup #{node['cluster']['cluster_user_home']}" do
  user 'root'
  group 'root'
  code <<-EOH
    set -e
    if [ -d /tmp#{node['cluster']['cluster_user_home']} ]; then
      echo "/tmp#{node['cluster']['cluster_user_home']} exists!"
      exit 1
    else
      mkdir -p /tmp#{node['cluster']['cluster_user_home']}
    fi
    rsync -a #{node['cluster']['cluster_user_home']}/ /tmp#{node['cluster']['cluster_user_home']}
  EOH
end

# Move the cluster user's default home directory
# This script performs the following actions:
# 1. Creates the new local home directory for the cluster user if it doesn't already exist.
# 2. Copies the data from the temporary backup directory (/tmp/cluster_user_home) to the new local home directory.
# 3. Updates the cluster user's home directory path to the new local home directory.
# 4. Changes the ownership of the new local home directory to the cluster user.
bash "Move #{node['cluster']['cluster_user_home']}" do
  user 'root'
  group 'root'
  code <<-EOH
    set -e
    mkdir -p #{node['cluster']['cluster_user_local_home']}
    rsync -a /tmp#{node['cluster']['cluster_user_home']}/ #{node['cluster']['cluster_user_local_home']}
    usermod -d #{node['cluster']['cluster_user_local_home']} #{node['cluster']['cluster_user']}
    chown -R #{node['cluster']['cluster_user']}: #{node['cluster']['cluster_user_local_home']}
  EOH
end

# Data integrity check and cleanup for temporary backup and original home directory
# 1. Verifies data integrity by comparing the original home directory and the new local home directory.
# 2. If the data integrity check passes, it removes both the temporary backup directory and the original home directory.
# 3. If the data integrity check fails, it outputs an error message and exits with an error code 1.
bash "Verify data integrity for #{node['cluster']['cluster_user_home']}" do
  user 'root'
  group 'root'
  code <<-EOH
    diff_output=$(diff -r #{node['cluster']['cluster_user_home']} #{node['cluster']['cluster_user_local_home']})
    if [[ $diff_output != *"Only in #{node['cluster']['cluster_user_home']}"* ]]; then
      rm -rf /tmp#{node['cluster']['cluster_user_home']}
      rm -rf #{node['cluster']['cluster_user_home']}
    else
      only_in_cluster_user_home=$(echo "$diff_output" | grep "Only in #{node['cluster']['cluster_user_home']}")
      echo "Data integrity check failed comparing #{node['cluster']['cluster_user_local_home']} and #{node['cluster']['cluster_user_home']}. Differences:"
      echo "$only_in_cluster_user_home"
      systemctl start sshd
      exit 1
    fi
  EOH
end

node.override['cluster']['cluster_user_home'] = node['cluster']['cluster_user_local_home']

# Start the sshd service again once the move is complete
service 'sshd' do
  action :start
  sensitive true
end
