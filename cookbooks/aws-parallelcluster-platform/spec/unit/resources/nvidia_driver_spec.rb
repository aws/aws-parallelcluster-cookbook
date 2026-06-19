require 'spec_helper'

class ConvergeNvidiaDriver
  def self.setup(chef_run, nvidia_driver_version: nil)
    chef_run.converge_dsl('aws-parallelcluster-platform') do
      nvidia_driver 'setup' do
        nvidia_driver_version nvidia_driver_version unless nvidia_driver_version.nil?
        action :setup
      end
    end
  end
end

describe 'nvidia_driver:nvidia_driver_version' do
  cached(:nvidia_driver_attribute) { 'nvidia_driver_attribute' }
  cached(:nvidia_driver_property) { 'nvidia_driver_property' }

  context 'when nvidia driver property is set' do
    cached(:chef_run) do
      allow_any_instance_of(Object).to receive(:nvidia_enabled?).and_return(false)
      ChefSpec::SoloRunner.new(step_into: ['nvidia_driver']) do |node|
        node.override['cluster']['nvidia']['driver_version'] = nvidia_driver_attribute
      end
    end
    cached(:resource) do
      ConvergeNvidiaDriver.setup(chef_run, nvidia_driver_version: nvidia_driver_property)
      chef_run.find_resource('nvidia_driver', 'setup')
    end

    it 'takes the value from nvidia driver property' do
      expect(resource.nvidia_driver_version).to eq(nvidia_driver_property)
    end
  end

  context 'when nvidia driver property is not set' do
    cached(:chef_run) do
      allow_any_instance_of(Object).to receive(:nvidia_enabled?).and_return(false)
      ChefSpec::SoloRunner.new(step_into: ['nvidia_driver'])
    end
    cached(:resource) do
      ConvergeNvidiaDriver.setup(chef_run)
      chef_run.find_resource('nvidia_driver', 'setup')
    end

    it 'defaults to the nvidia driver attribute' do
      expect(resource.nvidia_driver_version).to eq(chef_run.node['cluster']['nvidia']['driver_version'])
    end
  end
end

describe 'nvidia_driver:nvidia_open_kernel_modules?' do
  [%w(false false), [false, false], %w(no false), %w(true true), [true, true], %w(yes true)].each do |kernel_open, expected_open|
    context "node['cluster']['nvidia']['kernel_open'] is #{kernel_open}" do
      cached(:chef_run) do
        allow_any_instance_of(Object).to receive(:nvidia_enabled?).and_return(false)
        ChefSpec::SoloRunner.new(step_into: ['nvidia_driver']) do |node|
          node.override['cluster']['nvidia']['kernel_open'] = kernel_open
        end
      end
      cached(:resource) do
        ConvergeNvidiaDriver.setup(chef_run)
        chef_run.find_resource('nvidia_driver', 'setup')
      end
      it "is #{expected_open}" do
        expect(resource.nvidia_open_kernel_modules?).to eq(expected_open == 'true' || expected_open == true)
      end
    end
  end
end

describe 'nvidia_driver:nvidia_driver_enabled?' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner(platform: platform, version: version, step_into: ['nvidia_driver'])
      end
      cached(:resource) do
        ConvergeNvidiaDriver.setup(chef_run)
        chef_run.find_resource('nvidia_driver', 'setup')
      end

      context "when nvidia not enabled" do
        before { allow_any_instance_of(Object).to receive(:nvidia_enabled?).and_return(false) }

        it 'is false' do
          expect(resource.nvidia_driver_enabled?).to eq(false)
        end
      end

      context "when nvidia enabled" do
        before { allow_any_instance_of(Object).to receive(:nvidia_enabled?).and_return(true) }

        it 'is true' do
          expect(resource.nvidia_driver_enabled?).to eq(true)
        end
      end
    end
  end
end

describe 'nvidia_driver:setup' do
  for_all_oses do |platform, version|
    cached(:nvidia_driver_version) { 'nvidia_driver_version' }
    cached(:debian?) { platform == 'ubuntu' }

    context "on #{platform}#{version} when nvidia_driver not enabled" do
      cached(:chef_run) do
        stubs_for_resource('nvidia_driver') do |res|
          allow(res).to receive(:nvidia_driver_enabled?).and_return(false)
        end
        runner = runner(platform: platform, version: version, step_into: ['nvidia_driver'])
        ConvergeNvidiaDriver.setup(runner)
      end

      it 'does not install the driver' do
        is_expected.not_to run_execute('Enable NVIDIA driver module')
        is_expected.not_to install_apt_package('nvidia-open')
      end
    end

    context "on #{platform}#{version} when the driver is already installed" do
      cached(:chef_run) do
        stubs_for_resource('nvidia_driver') do |res|
          allow(res).to receive(:nvidia_driver_enabled?).and_return(true)
          allow(res).to receive(:kernel_modules_to_load).and_return([])
          allow(res).to receive(:gcc_major_version_used_by_kernel).and_return('12')
        end
        stub_command("lsinitramfs /boot/initrd.img-$(uname -r) | grep nouveau").and_return(false)
        mock_file_exists('/usr/bin/nvidia-smi', true)
        runner = runner(platform: platform, version: version, step_into: ['nvidia_driver']) do |node|
          node.automatic['kernel']['release'] = '6.anything'
        end
        ConvergeNvidiaDriver.setup(runner, nvidia_driver_version: nvidia_driver_version)
      end
      cached(:node) { chef_run.node }

      it 'does not install the driver (nvidia-smi already present)' do
        is_expected.not_to run_execute('Enable NVIDIA driver module')
        is_expected.not_to install_apt_package('nvidia-open')
      end

      it 'leaves the shipped driver untouched and records no version' do
        is_expected.not_to write_node_attributes('Save Nvidia driver version for Inspec tests')
      end
    end

    context "on #{platform}#{version} when nvidia_driver enabled and not yet installed" do
      cached(:chef_run) do
        stubs_for_resource('nvidia_driver') do |res|
          allow(res).to receive(:nvidia_driver_enabled?).and_return(true)
          allow(res).to receive(:gcc_major_version_used_by_kernel).and_return('12')
        end
        stub_command("lsinitramfs /boot/initrd.img-$(uname -r) | grep nouveau").and_return(true)
        mock_file_exists('/usr/bin/nvidia-smi', false)
        runner = runner(platform: platform, version: version, step_into: ['nvidia_driver']) do |node|
          node.automatic['kernel']['release'] = '6.anything'
        end
        ConvergeNvidiaDriver.setup(runner, nvidia_driver_version: nvidia_driver_version)
      end
      cached(:node) { chef_run.node }

      it 'dumps node attributes for InSpec' do
        is_expected.to write_node_attributes('Save Nvidia driver version for Inspec tests')
        expect(node['cluster']['nvidia']['driver_version']).to eq(nvidia_driver_version)
      end

      it 'sets up nvidia_driver' do
        is_expected.to setup_nvidia_driver('setup')
      end

      it 'uninstalls kernel module nouveau' do
        is_expected.to uninstall_kernel_module('nouveau')
      end

      it 'creates file blacklist-nouveau.conf' do
        is_expected.to create_cookbook_file('blacklist-nouveau.conf').with(
          source: 'nvidia/blacklist-nouveau.conf',
          path: '/etc/modprobe.d/blacklist-nouveau.conf',
          owner: 'root',
          group: 'root',
          mode: '0644'
        )
      end

      if platform == 'ubuntu'
        it 'installs the open driver meta-package' do
          is_expected.to install_apt_package('nvidia-open')
        end

        it 'does not hold the driver package (version-locking package handles pinning)' do
          is_expected.not_to run_execute('Hold nvidia-open')
        end

        it 'installs the NVIDIA version-locking package for the requested version' do
          is_expected.to install_apt_package("nvidia-driver-pinning-#{nvidia_driver_version}")
        end

        it 'rebuilds the initramfs' do
          is_expected.to run_execute('initramfs to remove nouveau').with_command('update-initramfs -u')
        end
      else
        it 'enables the open-dkms module stream and installs nvidia-open via dnf' do
          is_expected.to run_execute('Enable NVIDIA driver module').with(
            command: 'dnf -y module enable nvidia-driver:open-dkms'
          )
          is_expected.to install_dnf_package('nvidia-open')
        end

        it 'does not rebuild the initramfs' do
          is_expected.not_to run_execute('initramfs to remove nouveau')
        end
      end
    end
  end
end

describe 'nvidia_driver:setup with proprietary kernel modules' do
  for_all_oses do |platform, version|
    cached(:nvidia_driver_version) { 'nvidia_driver_version' }
    cached(:debian?) { platform == 'ubuntu' }

    context "on #{platform}#{version} when nvidia_driver enabled, proprietary and not yet installed" do
      cached(:chef_run) do
        stubs_for_resource('nvidia_driver') do |res|
          allow(res).to receive(:nvidia_driver_enabled?).and_return(true)
          allow(res).to receive(:gcc_major_version_used_by_kernel).and_return('12')
        end
        stub_command("lsinitramfs /boot/initrd.img-$(uname -r) | grep nouveau").and_return(true)
        mock_file_exists('/usr/bin/nvidia-smi', false)
        runner = runner(platform: platform, version: version, step_into: ['nvidia_driver']) do |node|
          node.automatic['kernel']['release'] = '6.anything'
          node.override['cluster']['nvidia']['kernel_open'] = 'false'
        end
        ConvergeNvidiaDriver.setup(runner, nvidia_driver_version: nvidia_driver_version)
      end

      if platform == 'ubuntu'
        it 'installs the proprietary cuda-drivers meta-package' do
          is_expected.to install_apt_package('cuda-drivers')
          is_expected.not_to install_apt_package('nvidia-open')
        end
      else
        it 'enables the latest-dkms module stream and installs cuda-drivers via dnf' do
          is_expected.to run_execute('Enable NVIDIA driver module').with(
            command: 'dnf -y module enable nvidia-driver:latest-dkms'
          )
          is_expected.to install_dnf_package('cuda-drivers')
          is_expected.not_to install_dnf_package('nvidia-open')
        end
      end
    end
  end
end
