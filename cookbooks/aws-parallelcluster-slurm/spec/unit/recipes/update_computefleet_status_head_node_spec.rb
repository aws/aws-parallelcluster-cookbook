# frozen_string_literal: true

# Copyright:: 2026 Amazon.com, Inc. and its affiliates. All Rights Reserved.
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

describe 'aws-parallelcluster-slurm::update_computefleet_status_head_node' do
  for_all_oses do |platform, version|
    scripts_dir = "/MOCK_SCRIPTS_DIR"
    computefleet_status_path = "/MOCK_COMPUTEFLEET_STATUS_PATH"

    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = runner(platform: platform, version: version) do |node|
          node.override['cluster']['scripts_dir'] = scripts_dir
          node.override['cluster']['computefleet_status_path'] = computefleet_status_path
        end
        runner.converge(described_recipe)
      end

      it 'runs the update compute fleet bash resource with correct configuration' do
        is_expected.to run_bash('update compute fleet').with(
          user: 'root',
          code: "      set -xe\n      #{scripts_dir}/slurm/slurm_fleet_status_manager -cf #{computefleet_status_path}\n"
        )
      end
    end
  end
end
