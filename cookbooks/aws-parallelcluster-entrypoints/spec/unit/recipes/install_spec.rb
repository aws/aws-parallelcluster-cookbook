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

describe 'aws-parallelcluster-entrypoints::install' do
  all_recipes = %w(
    aws-parallelcluster-shared::setup_envars
    aws-parallelcluster-platform::install
    aws-parallelcluster-environment::install
    aws-parallelcluster-computefleet::install
    aws-parallelcluster-slurm::install
  )

  setup_proxy_recipe = 'aws-parallelcluster-shared::setup_proxy'

  before do
    @included_recipes = []
    (all_recipes + [setup_proxy_recipe]).each do |recipe_name|
      allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).with(recipe_name) do
        @included_recipes << recipe_name
      end
    end
  end

  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      context "when ami is already bootstrapped" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['conditions']['ami_bootstrapped'] = true
          end
          runner.converge(described_recipe)
        end

        it "does not include any recipes" do
          chef_run
          expect(@included_recipes).to be_empty
        end
      end

      context "when ami is not bootstrapped" do
        context "when install_http_proxy_address is set" do
          cached(:chef_run) do
            runner = runner(platform: platform, version: version) do |node|
              node.override['conditions']['ami_bootstrapped'] = false
              node.override['cluster']['install_http_proxy_address'] = 'http://10.0.0.109:8888'
            end
            runner.converge(described_recipe)
          end

          it "includes setup_proxy recipe" do
            chef_run
            expect(@included_recipes).to include(setup_proxy_recipe)
          end
        end
      end
    end
  end
end
