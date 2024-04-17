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

describe 'aws-parallelcluster-slurm::config_head_node' do
  before do
    @included_recipes = []
    %w(
      aws-parallelcluster-slurm::config_head_node_directories
      aws-parallelcluster-slurm::config_check_login_stopped_script
      aws-parallelcluster-slurm::config_munge_key
      aws-parallelcluster-slurm::config_slurm_resume
      aws-parallelcluster-slurm::config_slurmctld_systemd_service
      aws-parallelcluster-slurm::config_health_check
    ).each do |recipe_name|
      allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).with(recipe_name) do
        @included_recipes << recipe_name
      end
    end
  end

  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = runner(platform: platform, version: version) do |node|
          allow_any_instance_of(Object).to receive(:nvidia_installed?).and_return(false)

          node.override['cluster']['node_type'] = 'HeadNode'
          node.override['cluster']['scheduler'] = 'slurm'
          node.override['cluster']['config'] = {}
        end
        runner.converge(described_recipe)
      end
      cached(:node) { chef_run.node }

      expected_recipes = %w(
          aws-parallelcluster-slurm::config_head_node_directories
          aws-parallelcluster-slurm::config_check_login_stopped_script
          aws-parallelcluster-slurm::config_munge_key
          aws-parallelcluster-slurm::config_slurm_resume
          aws-parallelcluster-slurm::config_slurmctld_systemd_service
          aws-parallelcluster-slurm::config_health_check
                                 )

      it "includes the recipes in the right order" do
        chef_run
        expect(@included_recipes).to eq(expected_recipes)
      end
    end
  end
end
