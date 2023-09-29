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

def fetch_and_decode_munge_key
  script_path = "#{node['cluster']['scripts_dir']}/slurm/update_munge_key.sh"

  declare_resource(:execute, 'fetch_and_decode_munge_key') do
    user 'root'
    group 'root'
    cwd ::File.dirname(script_path)
    command "./#{::File.basename(script_path)} -c True"
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
