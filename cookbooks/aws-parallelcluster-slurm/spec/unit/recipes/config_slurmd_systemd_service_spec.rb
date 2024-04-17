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

describe 'aws-parallelcluster-slurm::config_slurmd_systemd_service' do
  before do
    allow_any_instance_of(Object).to receive(:graphic_instance?).and_return(false)
    allow_any_instance_of(Object).to receive(:nvidia_installed?).and_return(false)
  end
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner(platform: platform, version: version).converge(described_recipe)
      end

      it 'creates the service definition for slurmd' do
        is_expected.to create_template('/etc/systemd/system/slurmd.service').with(
          source: 'slurm/compute/slurmd.service.erb',
          owner: 'root',
          group: 'root',
          mode:  '0644'
        )
      end

      it 'creates the service definition for slurmd with the correct settings' do
        is_expected.to render_file('/etc/systemd/system/slurmd.service')
          .with_content("After=munge.service network-online.target remote-fs.target")
      end
    end
  end
end
