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

describe 'aws-parallelcluster-environment::config' do
  before do
    @included_recipes = []
    # We assume this is the order in which the recipes are included
    @expected_recipes = %w(
      aws-parallelcluster-environment::ephemeral_drives
      aws-parallelcluster-environment::update_fs_mapping
      aws-parallelcluster-environment::export_home
      aws-parallelcluster-environment::export_internal_use_ebs
      aws-parallelcluster-environment::mount_intel_dir
      aws-parallelcluster-environment::ebs
      aws-parallelcluster-environment::raid
      aws-parallelcluster-environment::efs
      aws-parallelcluster-environment::fsx
      aws-parallelcluster-environment::config_cfn_hup
    )
    @expected_recipes.each do |recipe_name|
      allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).with(recipe_name) do
        @included_recipes << recipe_name
      end
    end
  end

  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      for_all_node_types do |node_type|
        context "when #{node_type}" do
          cached(:chef_run) do
            runner = runner(platform: platform, version: version) do |node|
              node.override['cluster']['node_type'] = node_type
              node.override['cluster']['shared_storage_type'] = 'ebs'
            end
            runner.converge(described_recipe)
          end
          cached(:node) { chef_run.node }

          it "includes the recipes in the right order" do
            chef_run
            expect(@included_recipes).to eq(@expected_recipes)
          end
        end
      end
    end
  end
end
