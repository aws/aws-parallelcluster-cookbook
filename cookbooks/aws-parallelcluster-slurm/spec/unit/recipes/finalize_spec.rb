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

describe 'aws-parallelcluster-slurm::finalize' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      context "when head node" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            allow_any_instance_of(Object).to receive(:are_mount_or_unmount_required?).and_return(false)
            allow_any_instance_of(Object).to receive(:dig).and_return(true)
            RSpec::Mocks.configuration.allow_message_expectations_on_nil = true

            node.override['cluster']['node_type'] = 'HeadNode'
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it 'includes the recipe to finalize the head node' do
          is_expected.to include_recipe('aws-parallelcluster-slurm::finalize_head_node')
        end
      end

      context "when compute node" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            allow_any_instance_of(Object).to receive(:are_mount_or_unmount_required?).and_return(false)
            allow_any_instance_of(Object).to receive(:dig).and_return(true)
            allow_any_instance_of(Object).to receive(:is_static_node?).and_return(false)
            RSpec::Mocks.configuration.allow_message_expectations_on_nil = true

            node.override['cluster']['node_type'] = 'ComputeFleet'
            node.override['interact_with_ddb'] = true
            node.override['ec2']['instance_id'] = "MOCK_INSTANCE_ID"
            node.override['cluster']['cluster_config_version'] = "MOCK_CLUSTER_CONFIG_VERSION"
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it 'includes the recipe to update the compute node' do
          is_expected.to include_recipe('aws-parallelcluster-slurm::finalize_compute')
        end
      end
    end
  end
end
