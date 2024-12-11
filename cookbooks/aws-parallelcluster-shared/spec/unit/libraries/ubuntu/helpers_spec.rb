require_relative '../../../../libraries/ubuntu/helpers'
require 'spec_helper'

describe 'gcc_major_version_used_by_kernel' do
  let(:cmd) { "cat /proc/version | grep -Eo 'gcc-[0-9]+' | cut -d '-' -f 2" }
  let(:shellout) { double(run_command: nil, error!: nil, stdout: '', stderr: '', exitstatus: 0, live_stream: '') }

  context 'when gcc version can be detected' do
    before do
      allow(Mixlib::ShellOut).to receive(:new).with(cmd, any_args).and_return(shellout)
      allow(shellout).to receive(:stdout).and_return("1")
    end

    it 'returns the correct gcc major version' do
      result = gcc_major_version_used_by_kernel
      expect(result).to eq("1")
    end
  end

  context 'when gcc version cannot be detected' do
    before do
      allow(Mixlib::ShellOut).to receive(:new).with(cmd, any_args).and_raise(Mixlib::ShellOut::ShellCommandFailed)
    end

    it 'returns an empty string' do
      result = gcc_major_version_used_by_kernel
      expect(result).to eq("")
    end
  end
end
