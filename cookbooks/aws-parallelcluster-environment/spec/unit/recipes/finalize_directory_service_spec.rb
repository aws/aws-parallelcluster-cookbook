# frozen_string_literal: true

# Copyright:: 2024 Amazon.com, Inc. and its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

require 'spec_helper'

describe 'aws-parallelcluster-environment::finalize_directory_service' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      for_all_node_types do |node_type|
        cluster_user = 'DEFAULT_CLUSTER_USER'
        domain_read_only_user = 'DOMAIN_READ_ONLY_USER'

        context "when #{node_type}" do
          cached(:chef_run) do
            runner = runner(platform: platform, version: version) do |node|
              node.override['cluster']['node_type'] = node_type
              node.override['cluster']['cluster_user'] = cluster_user
              node.override['cluster']['directory_service']['enabled'] = true

              allow_any_instance_of(Object).to receive(:domain_service_read_only_user_name).and_return(domain_read_only_user)
            end
            runner.converge(described_recipe)
          end
          cached(:node) { chef_run.node }

          if %(HeadNode LoginNode).include?(node_type)
            it 'fetches user data from remote directory service' do
              is_expected.to run_execute('Fetch user data from remote directory service').with(
                command: "sudo -u #{cluster_user} getent passwd #{domain_read_only_user}",
                user: 'root',
                retries: 10,
                retry_delay: 3
              )
            end
          else
            it 'fetches user data from remote directory service' do
              is_expected.not_to run_execute('Fetch user data from remote directory service')
            end
          end
        end
      end
    end
  end
end
