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

describe 'aws-parallelcluster-platform::update' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      context "when scheduler is slurm" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['scheduler'] = 'slurm'
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it 'it fetches and updates cluster configs' do
          is_expected.to run_fetch_config('Fetch and load cluster configs')
        end
        it 'it updates sudo access' do
          is_expected.to setup_sudo_access('Update Sudo Access')
        end
      end

      context "when scheduler is awsbatch" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['scheduler'] = 'awsbatch'
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it 'it fetches and updates cluster configs' do
          is_expected.to run_fetch_config('Fetch and load cluster configs')
        end
        it 'it doesnt update sudo access' do
          is_expected.not_to setup_sudo_access('Update Sudo Access')
        end
      end
    end
  end
end
