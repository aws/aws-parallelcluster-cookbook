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

describe 'aws-parallelcluster-slurm::update_login_node' do
  for_all_oses do |platform, version|
    cookbook_venv_path = "MOCK_COOKBOOK_VENV_PATH"
    cluster_name = "MOCK_CLUSTER_NAME"
    region = "MOCK_REGION"
    instance_id = "MOCK_INSTANCE_ID"
    cluster_config_version = "MOCK_CLUSTER_CONFIG_VERSION"
    time_now = "2024-01-16 15:30:45 UTC"

    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = runner(platform: platform, version: version) do |node|
          allow_any_instance_of(Object).to receive(:are_mount_or_unmount_required?).and_return(false)
          allow_any_instance_of(Object).to receive(:dig).and_return(true)
          allow_any_instance_of(Object).to receive(:cookbook_virtualenv_path).and_return(cookbook_venv_path)
          allow_any_instance_of(Object).to receive(:is_static_node?).and_return(false)
          allow(Time).to receive(:now).and_return(Time.parse(time_now))
          RSpec::Mocks.configuration.allow_message_expectations_on_nil = true

          node.override['cluster']['node_type'] = 'LoginNode'
          node.override['interact_with_ddb'] = true
          node.override['cluster']['cluster_name'] = cluster_name
          node.override['cluster']['region'] = region
          node.override['ec2']['instance_id'] = instance_id
          node.override['cluster']['cluster_config_version'] = cluster_config_version
        end
        runner.converge(described_recipe)
      end

      context "when mount/unmount is not required" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            allow_any_instance_of(Object).to receive(:are_mount_or_unmount_required?).and_return(false)
            allow_any_instance_of(Object).to receive(:dig).and_return(true)
            RSpec::Mocks.configuration.allow_message_expectations_on_nil = true

            node.override['cluster']['node_type'] = 'LoginNode'
            node.override['ec2']['instance_id'] = instance_id
            node.override['cluster']['cluster_config_version'] = cluster_config_version
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it 'does not update the shared storage' do
          is_expected.not_to run_ruby_block("update_shared_storages")
        end
      end

      context "when mount/unmount is required" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            allow_any_instance_of(Object).to receive(:are_mount_or_unmount_required?).and_return(true)
            allow_any_instance_of(Object).to receive(:dig).and_return(true)
            RSpec::Mocks.configuration.allow_message_expectations_on_nil = true

            node.override['cluster']['node_type'] = 'LoginNode'
            node.override['ec2']['instance_id'] = instance_id
            node.override['cluster']['cluster_config_version'] = cluster_config_version
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it 'updates the shared storage' do
          is_expected.to run_ruby_block("update_shared_storages")
        end
      end

      it 'saves the cluster config version to dynamodb' do
        expected_command = "#{cookbook_venv_path}/bin/aws dynamodb put-item" \
          " --table-name parallelcluster-#{cluster_name}"\
          " --item '{\"Id\": {\"S\": \"CLUSTER_CONFIG.#{instance_id}\"}, \"Data\": {\"M\": {\"cluster_config_version\": {\"S\": \"#{cluster_config_version}\"}, \"lastUpdateTime\": {\"S\": \"#{time_now}\"}}}}'" \
          " --region #{region}"
        is_expected.to run_execute("Save cluster config version to DynamoDB").with(
          command: expected_command,
          retries: 3,
          retry_delay: 5
        )
      end

      context "when interaction with ddb is disabled during kitchen tests" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            allow_any_instance_of(Object).to receive(:are_mount_or_unmount_required?).and_return(false)
            allow_any_instance_of(Object).to receive(:dig).and_return(true)
            allow_any_instance_of(Object).to receive(:is_static_node?).and_return(false)
            RSpec::Mocks.configuration.allow_message_expectations_on_nil = true

            node.override['cluster']['node_type'] = 'LoginNode'
            node.override['kitchen'] = true
            node.override['interact_with_ddb'] = false
            node.override['ec2']['instance_id'] = instance_id
            node.override['cluster']['cluster_config_version'] = cluster_config_version
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it 'does not saves the cluster config version to dynamodb' do
          is_expected.not_to run_execute("Save cluster config version to DynamoDB")
        end
      end
    end
  end
end
