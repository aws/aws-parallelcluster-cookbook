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

describe 'aws-parallelcluster-environment::update_fs_mapping' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      context "when head node" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['node_type'] = 'HeadNode'
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it 'generates the file shared_storages_data' do
          is_expected.to create_template("#{node['cluster']['etc_dir']}/shared_storages_data.yaml").with(
            source: "shared_storages/shared_storages_data.erb",
            owner: 'root',
            group: 'root',
            mode: '0644'
          )
        end
      end

      context "when compute node" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['node_type'] = 'HeadNode'
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it 'generates the file shared_storages_data' do
          is_expected.to create_template("#{node['cluster']['etc_dir']}/shared_storages_data.yaml").with(
            source: "shared_storages/shared_storages_data.erb",
            owner: 'root',
            group: 'root',
            mode: '0644'
          )
        end
      end

      context "when login node" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['node_type'] = 'LoginNode'
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it 'generates the file shared_storages_data' do
          is_expected.to create_template("#{node['cluster']['etc_dir']}/shared_storages_data.yaml").with(
            source: "shared_storages/shared_storages_data.erb",
            owner: 'root',
            group: 'root',
            mode: '0644'
          )
        end
      end
    end
  end
end
