# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-slurm
# Recipe:: config_head_node
#
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

resource_name :munge_key_manager
provides :munge_key_manager
unified_mode true

property :munge_key_secret_arn, String

default_action :setup_munge_key

def restart_munge_service
  declare_resource(:service, "munge") do
    supports restart: true
    action :restart
    retries 5
    retry_delay 10
  end unless on_docker?
end

def enable_munge_service
  declare_resource(:service, "munge") do
    supports restart: true
    action :enable
    retries 5
    retry_delay 10
  end unless on_docker?
end

def share_munge_key_to_dir(shared_dir)
  declare_resource(:bash, 'share_munge_key') do
    user 'root'
    group 'root'
    code <<-SHARE_MUNGE_KEY
      set -e
      mkdir -p #{shared_dir}/.munge
      # Copy key to shared dir
      cp /etc/munge/munge.key #{shared_dir}/.munge/.munge.key
      chmod 0700 #{shared_dir}/.munge
      chmod 0600 #{shared_dir}/.munge/.munge.key
    SHARE_MUNGE_KEY
  end
end

def share_munge
  share_munge_key_to_dir(node['cluster']['shared_dir'])
  share_munge_key_to_dir(node['cluster']['shared_dir_login_nodes'])
end

# TODO: Consider renaming 'generate_munge_key' and 'fetch_and_decode_munge_key' to more descriptive names that better convey their functionalities.
def fetch_and_decode_munge_key
  declare_resource(:execute, 'fetch_and_decode_munge_key') do
    user 'root'
    group 'root'
    command "/#{node['cluster']['scripts_dir']}/slurm/update_munge_key.sh -d"
  end
end

def generate_munge_key
  declare_resource(:bash, 'generate_munge_key') do
    user node['cluster']['munge']['user']
    group node['cluster']['munge']['group']
    cwd '/tmp'
    code <<-GENERATE_KEY
      set -e
      /usr/sbin/mungekey --verbose --force
      chmod 0600 /etc/munge/munge.key
    GENERATE_KEY
  end

  # This function randomly generates a new munge key.
  # After generating the key, it is essential to restart the munge service so that it starts using the new key.
  # Moreover, the new key has to be shared across relevant directories to ensure consistent authentication across the cluster.
  # We're restarting the munge service and sharing the munge key here within the `generate_munge_key` method,
  #  and not within the `fetch_and_decode_munge_key` method because the `update_munge_key.sh` script,
  #  which is called by `fetch_and_decode_munge_key`, already includes these two operations.
  restart_munge_service
  enable_munge_service
  share_munge
end

action :setup_munge_key do
  if new_resource.munge_key_secret_arn
    # This block will fetch the munge key from Secrets Manager
    fetch_and_decode_munge_key
  else
    # This block will randomly generate a munge key
    generate_munge_key
  end
end

action :update_munge_key do
  if new_resource.munge_key_secret_arn
    # This block will fetch the munge key from Secrets Manager and replace the previous munge key
    fetch_and_decode_munge_key
  else
    # This block will randomly generate a munge key and replace the previous munge key
    generate_munge_key
  end
end
