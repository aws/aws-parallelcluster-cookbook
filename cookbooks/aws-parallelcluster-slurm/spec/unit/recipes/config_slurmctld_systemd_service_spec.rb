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

describe 'aws-parallelcluster-slurm::config_slurmctld_systemd_service' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner(platform: platform, version: version).converge(described_recipe)
      end

      it 'creates the service definition for slurmctld' do
        is_expected.to create_template('/etc/systemd/system/slurmctld.service').with(
          source: 'slurm/head_node/slurmctld.service.erb',
          owner: 'root',
          group: 'root',
          mode:  '0644'
        )
      end

      it 'creates the service definition for slurmctld with the correct settings' do
        is_expected.to render_file('/etc/systemd/system/slurmctld.service')
          .with_content("After=network-online.target munge.service remote-fs.target")
      end
    end
  end
end
