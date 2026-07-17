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
require_relative '../../../libraries/command_runner'

describe ErrorHandlers::CommandRunner do
  let(:log_prefix) { 'TestPrefix:' }
  let(:runner) { described_class.new(log_prefix: log_prefix) }
  let(:command) { 'test command' }
  let(:description) { 'test operation' }
  let(:shell_out_result) { double('shell_out_result', exitstatus: 0, stdout: 'success', stderr: '') }

  before do
    allow(runner).to receive(:shell_out).and_return(shell_out_result)
    allow(runner).to receive(:sleep)
  end

  describe '#run_with_retries' do
    context 'when command succeeds on first attempt' do
      it 'returns true and does not retry' do
        expect(runner).to receive(:shell_out).once.and_return(shell_out_result)
        expect(runner).not_to receive(:sleep)
        expect(runner.run_with_retries(command, description: description)).to be true
      end

      it 'logs stdout and stderr' do
        allow(Chef::Log).to receive(:info)
        expect(Chef::Log).to receive(:info).with(/Command stdout: success/)
        expect(Chef::Log).to receive(:info).with(/Command stderr:/)
        runner.run_with_retries(command, description: description)
      end

      it 'logs success message' do
        allow(Chef::Log).to receive(:info)
        expect(Chef::Log).to receive(:info).with(/Successfully executed: test operation/)
        runner.run_with_retries(command, description: description)
      end
    end

    context 'when command fails then succeeds' do
      let(:failed_result) { double('failed_result', exitstatus: 1, stdout: '', stderr: 'error') }

      it 'retries and returns true on success' do
        expect(runner).to receive(:shell_out).and_return(failed_result, shell_out_result)
        expect(runner).to receive(:sleep).with(90).once
        expect(runner.run_with_retries(command, description: description, retries: 1)).to be true
      end

      it 'logs retry message' do
        allow(runner).to receive(:shell_out).and_return(failed_result, shell_out_result)
        allow(Chef::Log).to receive(:info)
        allow(Chef::Log).to receive(:warn)
        expect(Chef::Log).to receive(:info).with(/Retrying in 90 seconds/)
        runner.run_with_retries(command, description: description, retries: 1)
      end
    end

    context 'when command fails all attempts' do
      let(:failed_result) { double('failed_result', exitstatus: 1, stdout: '', stderr: 'error') }

      it 'returns false after exhausting retries' do
        allow(runner).to receive(:shell_out).and_return(failed_result)
        expect(runner.run_with_retries(command, description: description, retries: 1, retry_delay: 0)).to be false
      end

      it 'logs error after all attempts fail' do
        allow(runner).to receive(:shell_out).and_return(failed_result)
        expect(Chef::Log).to receive(:error).with(/Failed to test operation after 2 attempts/)
        runner.run_with_retries(command, description: description, retries: 1, retry_delay: 0)
      end

      it 'logs warning for each failed attempt' do
        allow(runner).to receive(:shell_out).and_return(failed_result)
        allow(Chef::Log).to receive(:info)
        allow(Chef::Log).to receive(:error)
        expect(Chef::Log).to receive(:warn).with(%r{Failed to test operation \(attempt 1/2\)})
        expect(Chef::Log).to receive(:warn).with(%r{Failed to test operation \(attempt 2/2\)})
        runner.run_with_retries(command, description: description, retries: 1, retry_delay: 0)
      end
    end

    context 'with custom retry parameters' do
      it 'respects custom retries count' do
        failed_result = double('failed_result', exitstatus: 1, stdout: '', stderr: 'error')
        allow(runner).to receive(:shell_out).and_return(failed_result)
        expect(runner).to receive(:shell_out).exactly(3).times
        runner.run_with_retries(command, description: description, retries: 2, retry_delay: 0)
      end

      it 'respects custom retry delay' do
        failed_result = double('failed_result', exitstatus: 1, stdout: '', stderr: 'error')
        allow(runner).to receive(:shell_out).and_return(failed_result, shell_out_result)
        expect(runner).to receive(:sleep).with(30).once
        runner.run_with_retries(command, description: description, retries: 1, retry_delay: 30)
      end

      it 'respects custom timeout' do
        expect(runner).to receive(:shell_out).with(command, timeout: 60).and_return(shell_out_result)
        runner.run_with_retries(command, description: description, timeout: 60)
      end
    end

    context 'with default parameters' do
      it 'uses DEFAULT_RETRIES' do
        failed_result = double('failed_result', exitstatus: 1, stdout: '', stderr: 'error')
        allow(runner).to receive(:shell_out).and_return(failed_result)
        expect(runner).to receive(:shell_out).exactly(11).times # 10 retries + 1 initial = 11 attempts
        runner.run_with_retries(command, description: description, retry_delay: 0)
      end

      it 'uses DEFAULT_TIMEOUT' do
        expect(runner).to receive(:shell_out).with(command, timeout: 30).and_return(shell_out_result)
        runner.run_with_retries(command, description: description)
      end
    end
  end
end
