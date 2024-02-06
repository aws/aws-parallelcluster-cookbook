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

describe 'aws-parallelcluster-slurm::finalize_head_node' do
  for_all_oses do |platform, version|
    cookbook_venv_path = "MOCK_COOKBOOK_VENV_PATH"
    cluster_name = "MOCK_CLUSTER_NAME"
    region = "MOCK_REGION"
    cluster_config_version = "MOCK_CLUSTER_CONFIG_VERSION"
    scripts_dir = "/MOCK_SCRIPTS_DIR"

    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = runner(platform: platform, version: version) do |node|
          allow_any_instance_of(Object).to receive(:cookbook_virtualenv_path).and_return(cookbook_venv_path)
          RSpec::Mocks.configuration.allow_message_expectations_on_nil = true

          node.override['cluster']['stack_name'] = cluster_name
          node.override['cluster']['region'] = region
          node.override['cluster']['cluster_config_version'] = cluster_config_version
          node.override['cluster']['scripts_dir'] = scripts_dir
        end
        runner.converge(described_recipe)
      end

      it 'checks cluster readiness' do
        expected_command = "#{cookbook_venv_path}/bin/python #{scripts_dir}/head_node_checks/check_cluster_ready.py" \
          " --cluster-name #{cluster_name}" \
          " --table-name parallelcluster-#{cluster_name}" \
          " --config-version #{cluster_config_version}" \
          " --region #{region}"
        is_expected.to run_execute("Check cluster readiness").with(
          command: expected_command,
          timeout: 30,
          retries: 5,
          retry_delay: 180
        )
      end
    end
  end
end
