require 'spec_helper'

class ConvergeNvidiaDriver
  def self.setup(chef_run, nvidia_driver_version: nil)
    chef_run.converge_dsl('aws-parallelcluster-platform') do
      nvidia_driver 'setup' do
        nvidia_driver_version nvidia_driver_version
        action :setup
      end
    end
  end
end

describe 'nvidia_driver:_nvidia_driver_version' do
  cached(:nvidia_driver_attribute) { 'nvidia_driver_attribute' }
  cached(:nvidia_driver_property) { 'nvidia_driver_property' }
  cached(:chef_run) do
    ChefSpec::SoloRunner.new(step_into: ['nvidia_driver']) do |node|
      node.override['cluster']['nvidia']['driver_version'] = nvidia_driver_attribute
    end
  end

  context 'when nvidia driver property is set' do
    cached(:resource) do
      ConvergeNvidiaDriver.setup(chef_run, nvidia_driver_version: nvidia_driver_property)
      chef_run.find_resource('nvidia_driver', 'setup')
    end

    it 'takes the value from nvidia driver property' do
      expect(resource._nvidia_driver_version).to eq(nvidia_driver_property)
    end
  end

  context 'when nvidia driver property is not set' do
    cached(:resource) do
      ConvergeNvidiaDriver.setup(chef_run)
      chef_run.find_resource('nvidia_driver', 'setup')
    end

    it 'takes the value from nvidia driver attribute' do
      expect(resource._nvidia_driver_version).to eq(nvidia_driver_attribute)
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
        before do
          allow_any_instance_of(Object).to receive(:nvidia_enabled?).and_return(false)
        end

        it 'is false' do
          expect(resource.nvidia_driver_enabled?).to eq(false)
        end
      end

      context "when nvidia enabled and arm instance" do
        before do
          allow_any_instance_of(Object).to receive(:nvidia_enabled?).and_return(true)
          allow_any_instance_of(Object).to receive(:arm_instance?).and_return(true)
        end

        if platform == 'centos'
          it 'is false' do
            expect(resource.nvidia_driver_enabled?).to eq(false)
          end
        else
          it 'is true' do
            expect(resource.nvidia_driver_enabled?).to eq(true)
          end
        end
      end

      context "when nvidia enabled and not arm instance" do
        before do
          allow_any_instance_of(Object).to receive(:nvidia_enabled?).and_return(true)
          allow_any_instance_of(Object).to receive(:arm_instance?).and_return(false)
        end

        it 'is true' do
          expect(resource.nvidia_driver_enabled?).to eq(true)
        end
      end
    end
  end
end

describe 'nvidia_driver:nvidia_kernel_module' do
  [%w(false kernel), [false, 'kernel'], %w(no kernel), %w(true kernel-open), [true, 'kernel-open'], %w(yes kernel-open)].each do |kernel_open, kernel_module|
    context "node['cluster']['nvidia']['kernel_open'] is #{kernel_open}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(step_into: ['nvidia_driver']) do |node|
          node.override['cluster']['nvidia']['kernel_open'] = kernel_open
        end
      end
      cached(:resource) do
        ConvergeNvidiaDriver.setup(chef_run)
        chef_run.find_resource('nvidia_driver', 'setup')
      end
      it "is #{kernel_module}" do
        allow_any_instance_of(Object).to receive(:nvidia_kernel_module).and_return(kernel_module)
        expect(resource.nvidia_kernel_module).to eq(kernel_module)
      end
    end
  end
end

describe 'nvidia_driver:nvidia_arch' do
  cached(:chef_run) do
    ChefSpec::SoloRunner.new(step_into: ['nvidia_driver'])
  end

  cached(:resource) do
    ConvergeNvidiaDriver.setup(chef_run)
    chef_run.find_resource('nvidia_driver', 'setup')
  end

  context 'when on arm' do
    it 'is aarch64' do
      allow_any_instance_of(Object).to receive(:arm_instance?).and_return(true)
      expect(resource.nvidia_arch).to eq('aarch64')
    end
  end

  context 'when not on arm' do
    it 'is x86_64' do
      allow_any_instance_of(Object).to receive(:arm_instance?).and_return(false)
      expect(resource.nvidia_arch).to eq('x86_64')
    end
  end
end

describe 'nvidia_driver:setup' do
  for_all_oses do |platform, version|
    cached(:nvidia_arch) { 'nvidia_arch' }
    cached(:nvidia_kernel_module) { 'nvidia_kernel_module' }
    cached(:nvidia_driver_version) { 'nvidia_driver_version' }
    cached(:nvidia_driver_url) { "https://us.download.nvidia.com/tesla/#{nvidia_driver_version}/NVIDIA-Linux-#{nvidia_arch}-#{nvidia_driver_version}.run" }

    context "on #{platform}#{version} when nvidia_driver not enabled" do
      cached(:chef_run) do
        stubs_for_resource('nvidia_driver') do |res|
          allow(res).to receive(:nvidia_driver_enabled?).and_return(false)
        end
        runner = runner(platform: platform, version: version, step_into: ['nvidia_driver'])
        ConvergeNvidiaDriver.setup(runner)
      end

      it 'does not install NVidia driver' do
        is_expected.not_to run_bash('nvidia.run advanced')
      end
    end

    [%w(false kernel), %w(true kernel-open)].each do |kernel_open, kernel_module|
      context "on #{platform}#{version} when nvidia_driver enabled and node['cluster']['nvidia']['kernel_open'] is #{kernel_open}" do
        if platform == 'centos'
          cached(:nvidia_driver_version) { '535.129.03' }
        else
          cached(:nvidia_driver_version) { 'nvidia_driver_version' }
        end
        cached(:nvidia_driver_url) { "https://us.download.nvidia.com/tesla/#{nvidia_driver_version}/NVIDIA-Linux-#{nvidia_arch}-#{nvidia_driver_version}.run" }
        cached(:chef_run) do
          stubs_for_resource('nvidia_driver') do |res|
            allow(res).to receive(:nvidia_driver_enabled?).and_return(true)
            allow(res).to receive(:nvidia_arch).and_return(nvidia_arch)
            allow(res).to receive(:nvidia_kernel_module).and_return(kernel_module)
          end

          stub_command("lsinitramfs /boot/initrd.img-$(uname -r) | grep nouveau").and_return(true)
          allow(::File).to receive(:exist?).with('/usr/bin/nvidia-smi').and_return(false)

          runner = runner(platform: platform, version: version, step_into: ['nvidia_driver']) do |node|
            node.automatic['kernel']['release'] = '5.anything'
          end

          ConvergeNvidiaDriver.setup(runner, nvidia_driver_version: nvidia_driver_version)
        end
        cached(:node) { chef_run.node }

        it 'dumps nodes attribues' do
          is_expected.to write_node_attributes('Save Nvidia driver version for Inspec tests')
        end

        it 'sets up nvidia_driver' do
          is_expected.to setup_nvidia_driver('setup')
        end

        it 'downloads nvidia driver' do
          is_expected.to create_remote_file('/tmp/nvidia.run').with(
            source: nvidia_driver_url,
            mode: '0755',
            retries: 3,
            retry_delay: 5
          )
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

        if platform == 'amazon'
          compiler_path = version == 2023 ? 'CC=/usr/bin/gcc' : 'CC=/usr/bin/gcc10-gcc'
          it 'installs gcc10' do
            is_expected.to install_package('gcc10').with_retries(10).with_retry_delay(5)
          end

          it 'creates dkms/nvidia.conf' do
            is_expected.to create_template('/etc/dkms/nvidia.conf').with(
              source: 'nvidia/amazon/dkms/nvidia.conf.erb',
              cookbook: 'aws-parallelcluster-platform',
              owner: 'root',
              group: 'root',
              mode: '0644',
              variables: { compiler_path: compiler_path }
            )
          end
          it 'installs nvidia driver' do
            is_expected.to run_bash('nvidia.run advanced')
              .with(
                user: 'root',
                group: 'root',
                cwd: '/tmp',
                creates: '/usr/bin/nvidia-smi'
              )
              .with_code(%r{CC=/usr/bin/gcc10-gcc ./nvidia.run --silent --dkms --disable-nouveau --no-cc-version-check -m=#{kernel_module}})
              .with_code(%r{rm -f /tmp/nvidia.run})
          end
        else
          it "doesn't install gcc10" do
            is_expected.not_to install_package('gcc10')
          end
          it 'installs nvidia driver' do
            is_expected.to run_bash('nvidia.run advanced')
              .with(
                user: 'root',
                group: 'root',
                cwd: '/tmp',
                creates: '/usr/bin/nvidia-smi'
              )
              .with_code(%r{./nvidia.run --silent --dkms --disable-nouveau --no-cc-version-check -m=#{kernel_module}})
              .with_code(%r{rm -f /tmp/nvidia.run})
          end
        end

        if platform == 'ubuntu'
          it 'executes initramfs to remove nouveau' do
            is_expected.to run_execute('initramfs to remove nouveau').with_command('update-initramfs -u')
          end
        else
          it 'does not execute initramfs to remove nouveau' do
            is_expected.not_to run_execute('initramfs to remove nouveau').with_command('update-initramfs -u')
          end
        end
      end
    end

    context "on #{platform}#{version}" do
      cached(:chef_run) do
        stubs_for_resource('nvidia_driver') do |res|
          allow(res).to receive(:nvidia_driver_enabled?).and_return(true)
          allow(res).to receive(:nvidia_arch).and_return(nvidia_arch)
          allow(res).to receive(:nvidia_kernel_module).and_return(nvidia_kernel_module)
        end
        runner(platform: platform, version: version, step_into: ['nvidia_driver'])
      end
      cached(:node) { chef_run.node }

      context "when nouveau removed" do
        before do
          stub_command("lsinitramfs /boot/initrd.img-$(uname -r) | grep nouveau").and_return(false)
          ConvergeNvidiaDriver.setup(chef_run, nvidia_driver_version: nvidia_driver_version)
        end

        it 'does not execute initramfs to remove nouveau' do
          is_expected.not_to run_execute('initramfs to remove nouveau').with_command('update-initramfs -u')
        end
      end

      context "when kernel version is not 5" do
        before do
          stub_command("lsinitramfs /boot/initrd.img-$(uname -r) | grep nouveau").and_return(false)
          node.automatic['kernel']['release'] = '4.anything'
          ConvergeNvidiaDriver.setup(chef_run, nvidia_driver_version: nvidia_driver_version)
        end

        it "doesn't install gcc10" do
          is_expected.not_to install_package('gcc10')
        end
      end
    end
  end
end
