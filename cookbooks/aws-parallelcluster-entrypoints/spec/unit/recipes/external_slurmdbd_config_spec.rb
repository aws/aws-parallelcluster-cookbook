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

recipes = %w(
      aws-parallelcluster-slurm::config_head_node_directories
      aws-parallelcluster-slurm::external_slurmdbd_disable_unrequired_services
      aws-parallelcluster-slurm::config_munge_key
      aws-parallelcluster-slurm::retrieve_slurmdbd_config_from_s3
      aws-parallelcluster-slurm::config_slurm_accounting
    )

describe 'aws-parallelcluster-entrypoints::external_slurmdbd_config' do
  before do
    @included_recipes = []
    recipes.each do |recipe_name|
      allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).with(recipe_name) do
        @included_recipes << recipe_name
      end
    end
  end

  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = runner(platform: platform, version: version)
        runner.converge(described_recipe)
      end

      it "includes the recipes in the right order" do
        chef_run
        expect(@included_recipes).to eq(recipes)
      end
    end
  end
end
