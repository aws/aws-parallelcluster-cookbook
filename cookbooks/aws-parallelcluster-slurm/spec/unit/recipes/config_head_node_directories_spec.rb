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

describe 'aws-parallelcluster-slurm::config_head_node_directories' do
  for_all_oses do |platform, version|
    scripts_dir = "/MOCK_SCRIPTS_DIR"

    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = runner(platform: platform, version: version) do |node|
          RSpec::Mocks.configuration.allow_message_expectations_on_nil = true

          node.override['cluster']['scripts_dir'] = scripts_dir
        end
        runner.converge(described_recipe)
      end

      it 'creates directory containing the scripts for head node checks' do
        is_expected.to create_remote_directory("#{scripts_dir}/head_node_checks").with(
          source: 'head_node_checks',
          mode: '0755',
          owner: 'root',
          group: 'root',
          recursive: true
        )
      end
    end
  end
end
