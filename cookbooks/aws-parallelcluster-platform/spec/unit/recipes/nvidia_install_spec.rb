require 'spec_helper'

describe 'aws-parallelcluster-platform::nvidia_install' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = runner(platform: platform, version: version)
        runner.converge(described_recipe)
      end
      cached(:node) { chef_run.node }

      it 'installs nvidia driver' do
        is_expected.to setup_nvidia_driver('Install Nvidia driver')
      end

      it 'installs cuda' do
        is_expected.to include_recipe('aws-parallelcluster-platform::cuda')
      end

      it 'installs gdrcopy' do
        is_expected.to setup_gdrcopy('Install Nvidia gdrcopy')
      end

      it 'installs nvidia_nvlsm' do
        is_expected.to install_nvidia_nvlsm('Install Nvidia NVLink Subnet Manager')
      end

      it 'installs fabric_manager' do
        is_expected.to setup_fabric_manager('Install Nvidia Fabric Manager')
      end

      it 'installs nvidia_dcgm' do
        is_expected.to setup_nvidia_dcgm('install Nvidia datacenter-gpu-manager')
      end

      it 'installs nvidia_imex' do
        is_expected.to install_nvidia_imex('Install nvidia-imex')
      end
    end
  end
end
