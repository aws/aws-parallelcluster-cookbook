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

default_action :manage

action :manage do
  if new_resource.munge_key_secret_arn
    # This block will fetch the munge key from Secrets Manager
    bash 'fetch_and_decode_munge_key' do
      user 'root'
      group 'root'
      cwd '/tmp'
      code <<-FETCH_AND_DECODE
        # Get encoded munge key from secrets manager and decode it
        encoded_key=$(aws secretsmanager get-secret-value --secret-id #{new_resource.munge_key_secret_arn} --query 'SecretString' --output text)
        echo $encoded_key | base64 -d > /etc/munge/munge.key
        # Set ownership on the key
        chown #{node['cluster']['munge']['user']}:#{node['cluster']['munge']['group']} /etc/munge/munge.key
        # Enforce correct permission on the key
        chmod 0600 /etc/munge/munge.key
      FETCH_AND_DECODE
    end
  else
    # This block will generate a munge key if it doesn't exist
    bash 'generate_munge_key' do
      not_if { ::File.exist?('/etc/munge/munge.key') }
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
