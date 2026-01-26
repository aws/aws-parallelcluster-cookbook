# frozen_string_literal: true

# Copyright:: 2025 Amazon.com, Inc. and its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

require_relative '../../spec_helper'
require_relative '../../../libraries/update_failure_handler'

describe ErrorHandlers::UpdateFailureHandler do
  let(:handler) { described_class.new }
  let(:exception) { StandardError.new('Test error') }
  let(:resource1) { double('resource1', to_s: 'file[/tmp/test]') }
  let(:updated_resources) { [resource1] }
  let(:action_collection) { double('action_collection') }
  let(:pyenv_root) { '/opt/parallelcluster/pyenv' }
  let(:python_version) { '3.9.0' }
  let(:scripts_dir) { '/opt/parallelcluster/scripts' }
  let(:region) { 'us-east-1' }
  let(:virtualenv_path) { "#{pyenv_root}/versions/#{python_version}/envs/cookbook_virtualenv" }
  let(:node) do
    {
      'cluster' => {
        'node_type' => node_type,
        'system_pyenv_root' => pyenv_root,
        'python-version' => python_version,
        'scripts_dir' => scripts_dir,
        'region' => region,
      },
    }
  end
  let(:node_type) { 'HeadNode' }
  let(:run_status) { double('run_status', exception: exception, updated_resources: updated_resources, node: node) }
  let(:command_runner) { instance_double(ErrorHandlers::CommandRunner) }

  before do
    allow(handler).to receive(:run_status).and_return(run_status)
    allow(handler).to receive(:action_collection).and_return(action_collection)
    allow(action_collection).to receive(:filtered_collection).and_return([])
    allow(handler).to receive(:command_runner).and_return(command_runner)
    allow(command_runner).to receive(:run_with_retries).and_return(true)
  end

  describe '#node_type' do
    it 'returns the node type from cluster attributes' do
      expect(handler.node_type).to eq('HeadNode')
    end
  end

  describe '#cookbook_virtualenv_path' do
    it 'constructs the correct virtualenv path' do
      expect(handler.cookbook_virtualenv_path).to eq(virtualenv_path)
    end
  end

  describe '#report' do
    context 'when node type is HeadNode' do
      it 'writes error report and runs recovery commands' do
        expect(handler).to receive(:write_error_report)
        expect(handler).to receive(:run_recovery)
        handler.report
      end

      it 'catches and logs exceptions during recovery' do
        allow(handler).to receive(:write_error_report).and_raise(StandardError.new('Recovery failed'))
        expect(Chef::Log).to receive(:error).with(/Failed with error: Recovery failed/)
        expect(Chef::Log).to receive(:error).with(/Backtrace:/)
        handler.report
      end
    end

    context 'when node type is not HeadNode' do
      let(:node_type) { 'ComputeFleet' }

      it 'skips recovery and returns early' do
        expect(handler).not_to receive(:write_error_report)
        expect(handler).not_to receive(:run_recovery)
        allow(Chef::Log).to receive(:info)
        expect(Chef::Log).to receive(:info).with(/Node type is ComputeFleet/)
        handler.report
      end
    end
  end

  describe '#write_error_report' do
    it 'logs the exception and updated resources' do
      expect(Chef::Log).to receive(:info).with(/Update failed on HeadNode due to: Test error/)
      expect(Chef::Log).to receive(:info).with(/Resources that have been successfully executed/)
      expect(Chef::Log).to receive(:info).with(%r{file\[/tmp/test\]})
      handler.write_error_report
    end
  end

  describe '#run_recovery' do
    it 'cleans up DNA files and starts clustermgtd unconditionally' do
      expect(handler).to receive(:cleanup_dna_files).ordered
      expect(handler).to receive(:start_clustermgtd).ordered
      handler.run_recovery
    end
  end

  describe '#cleanup_dna_files' do
    it 'runs the cleanup command with correct arguments' do
      expected_command = "#{virtualenv_path}/bin/python #{scripts_dir}/share_compute_fleet_dna.py --region #{region} --cleanup"
      expect(command_runner).to receive(:run_with_retries).with(expected_command, description: "cleanup DNA files")
      handler.cleanup_dna_files
    end
  end

  describe '#start_clustermgtd' do
    it 'runs the supervisorctl command' do
      expected_command = "#{virtualenv_path}/bin/supervisorctl start clustermgtd"
      expect(command_runner).to receive(:run_with_retries).with(expected_command, description: "start clustermgtd")
      handler.start_clustermgtd
    end
  end

  describe '#command_runner' do
    before do
      allow(handler).to receive(:command_runner).and_call_original
    end

    it 'returns a CommandRunner instance' do
      expect(handler.command_runner).to be_a(ErrorHandlers::CommandRunner)
    end

    it 'memoizes the command runner' do
      expect(handler.command_runner).to be(handler.command_runner)
    end
  end

  describe '#resource_succeeded?' do
    let(:resource_name) { 'test resource' }
    let(:test_resource) { double('test_resource', resource_name: :execute, name: resource_name) }

    context 'when resource was updated' do
      let(:action_record) { double('action_record', new_resource: test_resource, status: :updated) }

      before { allow(action_collection).to receive(:filtered_collection).and_return([action_record]) }

      it 'returns true' do
        expect(handler.resource_succeeded?(resource_name)).to be true
      end
    end

    context 'when resource was up_to_date' do
      let(:action_record) { double('action_record', new_resource: test_resource, status: :up_to_date) }

      before { allow(action_collection).to receive(:filtered_collection).and_return([action_record]) }

      it 'returns true' do
        expect(handler.resource_succeeded?(resource_name)).to be true
      end
    end

    context 'when resource was not executed' do
      before { allow(action_collection).to receive(:filtered_collection).and_return([]) }

      it 'returns false' do
        expect(handler.resource_succeeded?(resource_name)).to be false
      end
    end

    context 'when resource failed' do
      let(:action_record) { double('action_record', new_resource: test_resource, status: :failed) }

      before { allow(action_collection).to receive(:filtered_collection).and_return([action_record]) }

      it 'returns false' do
        expect(handler.resource_succeeded?(resource_name)).to be false
      end
    end
  end

  describe '#resource_status' do
    let(:resource_name) { 'test resource' }
    let(:test_resource) { double('test_resource', resource_name: :execute, name: resource_name) }

    context 'when resource was not executed' do
      before { allow(action_collection).to receive(:filtered_collection).and_return([]) }

      it 'returns :not_executed' do
        expect(handler.resource_status(resource_name)).to eq(:not_executed)
      end
    end

    context 'when resource was executed' do
      let(:action_record) { double('action_record', new_resource: test_resource, status: :updated) }

      before { allow(action_collection).to receive(:filtered_collection).and_return([action_record]) }

      it 'returns the resource status' do
        expect(handler.resource_status(resource_name)).to eq(:updated)
      end
    end
  end
end
