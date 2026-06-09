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

describe 'aws-parallelcluster-slurm::config_slurm_resume' do
  RESUME_CONF = '/etc/parallelcluster/slurm_plugin/parallelcluster_slurm_resume.conf'

  # The template passes instance_info_retrieval_timeout as a lazy attribute, which ChefSpec does not
  # evaluate during rendering. Evaluate the lazy value directly off the template resource instead.
  def rendered_timeout(chef_run)
    chef_run.find_resource(:template, RESUME_CONF).variables[:instance_info_retrieval_timeout].call
  end

  context 'when ComputeInstanceInfoTimeout is set in DevSettings/Timeouts' do
    cached(:chef_run) do
      runner = runner(platform: 'amazon', version: '2023') do |node|
        allow_any_instance_of(Object).to receive(:on_docker?).and_return(true)
        node.override['cluster']['config'] = { DevSettings: { Timeouts: { ComputeInstanceInfoTimeout: 150 } } }
      end
      runner.converge(described_recipe)
    end

    it 'uses the configured value' do
      expect(rendered_timeout(chef_run)).to eq(150)
    end
  end

  context 'when ComputeInstanceInfoTimeout is not set' do
    cached(:chef_run) do
      runner = runner(platform: 'amazon', version: '2023') do |node|
        allow_any_instance_of(Object).to receive(:on_docker?).and_return(true)
        node.override['cluster']['config'] = {}
      end
      runner.converge(described_recipe)
    end

    it 'falls back to the compute_instance_info_timeout default' do
      expect(rendered_timeout(chef_run)).to eq(chef_run.node['cluster']['compute_instance_info_timeout'])
    end
  end
end
