require 'spec_helper'

describe 'aws-parallelcluster-platform::nvidia_config' do
  context 'when nvidia installed' do
    before do
      allow_any_instance_of(Object).to receive(:nvidia_installed?).and_return(true)
      allow_any_instance_of(Object).to receive(:graphic_instance?).and_return(true)
    end

    it 'configures fabric_manager' do
      is_expected.to configure_fabric_manager('Configure fabric manager')
    end

    it 'configures gdrcopy' do
      is_expected.to configure_gdrcopy('Configure gdrcopy')
    end

    it 'loads nvidia-uvm kernel module' do
      is_expected.to load_kernel_module('nvidia-uvm')
    end

    it 'makes sure kernel module Nvidia-uvm is loaded at instance boot time' do
      is_expected.to create_cookbook_file('nvidia.conf').with(
        source: 'nvidia/nvidia.conf',
        path: '/etc/modules-load.d/nvidia.conf',
        owner: 'root',
        group: 'root',
        mode: '0644'
      )
    end

    it 'creates the parallelcluster nvidia template with the correct attributes' do
      is_expected.to create_template('/etc/systemd/system/parallelcluster_nvidia.service').with(
        source: 'nvidia/parallelcluster_nvidia_service.erb',
        owner: 'root',
        group: 'root',
        mode:  '0644',
        variables: { is_nvidia_persistenced_running: is_process_running('nvidia-persistenced') }
      )
    end

    it 'starts parallelcluster_nvidia service' do
      is_expected.to enable_service('parallelcluster_nvidia').with_action(%i(enable start))
    end

    context 'when nvidia-peristenced process is running' do
      before do
        allow_any_instance_of(Object).to receive(:is_process_running?).and_return(true)
      end

      it 'creates the parallelcluster nvidia template with the correct attributes' do
        is_expected.to create_template('/etc/systemd/system/parallelcluster_nvidia.service').with(
          source: 'nvidia/parallelcluster_nvidia_service.erb',
          owner: 'root',
          group: 'root',
          mode:  '0644',
          variables: { is_nvidia_persistenced_running: is_process_running('nvidia-persistenced') }
        )
      end
    end

    context 'when nvidia-peristenced process is not running' do
      before do
        allow_any_instance_of(Object).to receive(:is_process_running?).and_return(false)
      end

      it 'creates the parallelcluster nvidia template with the correct attributes' do
        is_expected.to create_template('/etc/systemd/system/parallelcluster_nvidia.service').with(
          source: 'nvidia/parallelcluster_nvidia_service.erb',
          owner: 'root',
          group: 'root',
          mode:  '0644',
          variables: { is_nvidia_persistenced_running: is_process_running('nvidia-persistenced') }
        )
      end
    end
  end

  context 'when not a graphic instance' do
    before do
      allow_any_instance_of(Object).to receive(:nvidia_installed?).and_return(true)
      allow_any_instance_of(Object).to receive(:graphic_instance?).and_return(false)
    end

    it 'does not configure uvm' do
      is_expected.not_to load_kernel_module('nvidia-uvm')
      is_expected.not_to create_cookbook_file('nvidia.conf')
      is_expected.not_to create_template('/etc/systemd/system/parallelcluster_nvidia.service')
      is_expected.not_to enable_service('parallelcluster_nvidia')
    end
  end

  context 'when nvidia not installed' do
    before do
      allow_any_instance_of(Object).to receive(:nvidia_installed?).and_return(false)
      allow_any_instance_of(Object).to receive(:graphic_instance?).and_return(true)
    end

    it 'does not configure uvm' do
      is_expected.not_to load_kernel_module('nvidia-uvm')
      is_expected.not_to create_cookbook_file('nvidia.conf')
      is_expected.not_to create_template('/etc/systemd/system/parallelcluster_nvidia.service')
      is_expected.not_to enable_service('parallelcluster_nvidia')
    end
  end
end
