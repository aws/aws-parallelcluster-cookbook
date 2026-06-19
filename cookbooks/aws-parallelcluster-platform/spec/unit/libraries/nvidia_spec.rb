# frozen_string_literal: true

require 'spec_helper'

# -------------------------------------------------------------------
# nvidia_enabled? — tested via the nvidia_install recipe guard.
# The recipe returns early if nvidia_enabled? is false.
# -------------------------------------------------------------------
describe 'nvidia_enabled? via nvidia_driver resource' do
  [
    ['yes', true],
    [true, true],
    ['true', true],
    ['no', false],
    [false, false],
    ['false', false],
    ['any_other_value', false],
  ].each do |input, should_install|
    context "when node['cluster']['nvidia']['enabled'] is #{input.inspect}" do
      cached(:chef_run) do
        allow(::File).to receive(:exist?).and_call_original
        allow(::File).to receive(:exist?).with('/usr/bin/nvidia-smi').and_return(false)
        stub_command("lsinitramfs /boot/initrd.img-$(uname -r) | grep nouveau").and_return(false)
        ChefSpec::SoloRunner.new(step_into: ['nvidia_driver']) do |node|
          node.override['cluster']['nvidia']['enabled'] = input
        end.converge('aws-parallelcluster-platform::nvidia_install')
      end

      if should_install
        it 'installs the nvidia driver' do
          is_expected.to create_cookbook_file('blacklist-nouveau.conf')
        end
      else
        it 'does not install the nvidia driver' do
          is_expected.not_to create_cookbook_file('blacklist-nouveau.conf')
        end
      end
    end
  end
end
