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

describe 'aws-parallelcluster-entrypoints::update' do
  before do
    @included_recipes = []
    %w(
      aws-parallelcluster-platform::update
      aws-parallelcluster-environment::update
      aws-parallelcluster-slurm::update
      aws-parallelcluster-computefleet::update_parallelcluster_node
    ).each do |recipe_name|
      allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).with(recipe_name) do
        @included_recipes << recipe_name
      end
    end
  end

  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      for_all_node_types do |node_type|
        context "when #{node_type}" do
          [true, false].each do |is_custom_node|
            context "and does #{'not ' unless is_custom_node}use a custom node package" do
              cached(:chef_run) do
                runner = runner(platform: platform, version: version) do |node|
                  allow_any_instance_of(Object).to receive(:fetch_config).and_return(OpenStruct.new)

                  node.override['cluster']['node_type'] = node_type
                  node.override['cluster']['scheduler'] = 'slurm'
                  node.override['cluster']['custom_node_package'] = "CUSTOM_NODE_PACKAGE" if is_custom_node
                end
                runner.converge(described_recipe)
              end
              cached(:node) { chef_run.node }

              expected_recipes = %w(
                                  aws-parallelcluster-platform::update
                                  aws-parallelcluster-environment::update
                                  aws-parallelcluster-slurm::update
                                )

              if is_custom_node
                expected_recipes = expected_recipes.append("aws-parallelcluster-computefleet::update_parallelcluster_node")
              end

              it "includes the recipes in the right order" do
                chef_run
                expect(@included_recipes).to eq(expected_recipes)
              end
            end
          end
        end
      end
    end
  end
end
