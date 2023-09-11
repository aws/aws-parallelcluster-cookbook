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

resource_name :munge_key_update_manager
provides :munge_key_update_manager
unified_mode true

property :munge_key_secret_arn, String

default_action :update_munge_key

action :update_munge_key do
  bash 'remove_current_munge_key' do
    user 'root'
    group 'root'
    cwd '/tmp'
    code <<-REMOVE_CURRENT_MUNGE_KEY
      if [ -f "/etc/munge/munge.key" ]; then
        rm -f /etc/munge/munge.key
      fi
    REMOVE_CURRENT_MUNGE_KEY
  end

  if new_resource.munge_key_secret_arn
    bash 'fetch_and_decode_munge_key' do
      user 'root'
      group 'root'
      cwd '/tmp'
      code <<-FETCH_AND_DECODE
        # Get encoded munge key from secrets manager
        encoded_key=$(aws secretsmanager get-secret-value --secret-id #{new_resource.munge_key_secret_arn} --query 'SecretString' --output text --region #{node['cluster']['region']})
        # If encoded_key doesn't have a value, error and exit
        if [ -z "$encoded_key" ]; then
          echo "Error fetching munge key from Secrets Manager or the key is empty"
          exit 1
        fi

        # Decode munge key and write to /etc/munge/munge.key
        decoded_key=$(echo $encoded_key | base64 -d)
        if [ $? -ne 0 ]; then
          echo "Error decoding the munge key with base64"
          exit 1
        fi

        echo "$decoded_key" > /etc/munge/munge.key

        # Set ownership on the key
        chown #{node['cluster']['munge']['user']}:#{node['cluster']['munge']['group']} /etc/munge/munge.key
        # Enforce correct permission on the key
        chmod 0600 /etc/munge/munge.key
      FETCH_AND_DECODE
    end
  else
    bash 'generate_munge_key' do
      user node['cluster']['munge']['user']
      group node['cluster']['munge']['group']
      cwd '/tmp'
      code <<-GENERATE_KEY
        set -e
        /usr/sbin/mungekey --verbose
        chmod 0600 /etc/munge/munge.key
      GENERATE_KEY
    end
  end
end
