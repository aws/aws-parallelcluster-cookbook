require 'spec_helper'

describe 'aws-parallelcluster-platform::nvidia_install' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      context 'when nvidia is disabled' do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['nvidia']['enabled'] = 'no'
          end
          runner.converge(described_recipe)
        end

        it 'skips the entire nvidia software stack' do
          is_expected.not_to add_driver_repo_nvidia_repo('Add NVIDIA driver local repo')
          is_expected.not_to setup_nvidia_driver('Install Nvidia driver')
          is_expected.not_to install_nvidia_imex('Install nvidia-imex')
          is_expected.not_to setup_nvidia_cuda('Install Nvidia CUDA')
        end
      end

      context 'when the nvidia driver is already installed on the base AMI' do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['nvidia']['enabled'] = 'yes'
          end
          allow_any_instance_of(Object).to receive(:nvidia_installed?).and_return(true)
          runner.converge(described_recipe)
        end

        it 'skips the entire nvidia software stack' do
          is_expected.not_to add_driver_repo_nvidia_repo('Add NVIDIA driver local repo')
          is_expected.not_to setup_nvidia_driver('Install Nvidia driver')
          is_expected.not_to install_nvidia_imex('Install nvidia-imex')
          is_expected.not_to setup_nvidia_cuda('Install Nvidia CUDA')
        end
      end

      cached(:chef_run) do
        runner = runner(platform: platform, version: version) do |node|
          node.override['cluster']['nvidia']['enabled'] = 'yes'
        end
        allow_any_instance_of(Object).to receive(:nvidia_installed?).and_return(false)
        runner.converge(described_recipe)
      end
      cached(:node) { chef_run.node }

      it 'adds the NVIDIA driver local repo' do
        is_expected.to add_driver_repo_nvidia_repo('Add NVIDIA driver local repo')
      end

      it 'installs nvidia driver' do
        is_expected.to setup_nvidia_driver('Install Nvidia driver')
      end

      it 'installs nvidia_nvlsm' do
        is_expected.to install_nvidia_nvlsm('Install Nvidia NVLink Subnet Manager')
      end

      it 'installs fabric_manager' do
        is_expected.to setup_fabric_manager('Install Nvidia Fabric Manager')
      end

      it 'installs nvidia_imex' do
        is_expected.to install_nvidia_imex('Install nvidia-imex')
      end

      it 'removes the NVIDIA driver local repo once the driver stack is installed' do
        is_expected.to remove_driver_repo_nvidia_repo('Remove NVIDIA driver local repo')
      end

      it 'adds the NVIDIA CUDA local repo' do
        is_expected.to add_cuda_repo_nvidia_repo('Add NVIDIA CUDA local repo')
      end

      it 'installs cuda' do
        is_expected.to setup_nvidia_cuda('Install Nvidia CUDA')
      end

      it 'removes the NVIDIA CUDA local repo once CUDA is installed' do
        is_expected.to remove_cuda_repo_nvidia_repo('Remove NVIDIA CUDA local repo')
      end

      it 'installs gdrcopy' do
        is_expected.to setup_gdrcopy('Install Nvidia gdrcopy')
      end

      it 'installs nvidia_dcgm' do
        is_expected.to setup_nvidia_dcgm('install Nvidia datacenter-gpu-manager')
      end

      it 'never registers the driver and CUDA local repos at the same time' do
        expected_order = [
          'Add NVIDIA driver local repo',
          'Install Nvidia driver',
          'Install Nvidia NVLink Subnet Manager',
          'Install Nvidia Fabric Manager',
          'Install nvidia-imex',
          'Remove NVIDIA driver local repo',
          'Add NVIDIA CUDA local repo',
          'Install Nvidia CUDA',
          'Remove NVIDIA CUDA local repo',
          'Install Nvidia gdrcopy',
          'install Nvidia datacenter-gpu-manager',
        ]
        actual_order = chef_run.run_context.resource_collection.map(&:name).select { |name| expected_order.include?(name) }
        expect(actual_order).to eq(expected_order)
      end
    end
  end
end
