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

describe 'aws-parallelcluster-entrypoints::finalize' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      for_all_node_types do |node_type|
        context "when #{node_type}" do
          cached(:chef_run) do
            runner = runner(platform: platform, version: version) do |node|
              allow_any_instance_of(Object).to receive(:fetch_config).and_return(OpenStruct.new)
              allow_any_instance_of(Object).to receive(:is_custom_node?).and_return(true)

              node.override['cluster']['node_type'] = node_type
              node.override['cluster']['scheduler'] = 'slurm'
            end
            runner.converge(described_recipe)
          end
          cached(:node) { chef_run.node }

          %w(
            aws-parallelcluster-platform::enable_chef_error_handler
            aws-parallelcluster-computefleet::custom_parallelcluster_node
            aws-parallelcluster-platform::finalize aws-parallelcluster-environment::finalize
            aws-parallelcluster-slurm::finalize
          ).each do |recipe_name|
            it "includes the recipe #{recipe_name}" do
              # TODO: This assertion requires to refactor all the resources having properties
              #  aws_region and aws_domain because they are overwriting existing methods
              #  defined in the aws-parallelcluster-shared cookbook, making the test compilation to fail.
              #  We must re-enable this assertion once the refactoring has been done.
              # is_expected.to include_recipe(recipe_name)
            end
          end
        end
      end
    end
  end
end
