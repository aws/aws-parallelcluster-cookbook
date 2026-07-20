require 'spec_helper'

class ConvergeFabricManager
  def self.setup(chef_run, nvidia_enabled: nil)
    chef_run.converge_dsl('aws-parallelcluster-platform') do
      fabric_manager 'setup' do
        nvidia_enabled nvidia_enabled
        action :setup
      end
    end
  end

  def self.configure(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-platform') do
      fabric_manager 'configure' do
        action :configure
      end
    end
  end
end

describe 'fabric_manager:_nvidia_enabled' do
  context 'when nvidia enabled property is set' do
    cached(:chef_run) do
      ChefSpec::SoloRunner.new(step_into: ['fabric_manager']) do |node|
        node.override['cluster']['nvidia']['enabled'] = false
      end
    end
    cached(:resource) do
      ConvergeFabricManager.setup(chef_run, nvidia_enabled: true)
      chef_run.find_resource('fabric_manager', 'setup')
    end

    it "takes precedence over node['cluster']['nvidia']['enabled'] attribute" do
      expect(resource._nvidia_enabled).to eq(true)
    end
  end

  context 'when nvidia enabled property is not set' do
    context "and node['cluster']['nvidia']['enabled'] is true" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(step_into: ['fabric_manager']) do |node|
          node.override['cluster']['nvidia']['enabled'] = true
        end
      end
      cached(:resource) do
        ConvergeFabricManager.setup(chef_run)
        chef_run.find_resource('fabric_manager', 'setup')
      end
      it "is true" do
        expect(resource._nvidia_enabled).to eq(true)
      end
    end

    context "and node['cluster']['nvidia']['enabled'] is yes" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(step_into: ['fabric_manager']) do |node|
          node.override['cluster']['nvidia']['enabled'] = 'yes'
        end
      end
      cached(:resource) do
        ConvergeFabricManager.setup(chef_run)
        chef_run.find_resource('fabric_manager', 'setup')
      end
      it "is true" do
        expect(resource._nvidia_enabled).to eq(true)
      end
    end

    context "and node['cluster']['nvidia']['enabled'] is not yes or true" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(step_into: ['fabric_manager']) do |node|
          node.override['cluster']['nvidia']['enabled'] = 'any'
        end
      end
      cached(:resource) do
        ConvergeFabricManager.setup(chef_run)
        chef_run.find_resource('fabric_manager', 'setup')
      end
      it "is false" do
        expect(resource._nvidia_enabled).to eq(false)
      end
    end
  end
end

describe 'fabric_manager:_fabric_manager_enabled' do
  context 'when on arm' do
    cached(:chef_run) do
      allow_any_instance_of(Object).to receive(:arm_instance?).and_return(true)
      ChefSpec::SoloRunner.new(step_into: ['fabric_manager'])
    end
    cached(:resource) do
      ConvergeFabricManager.setup(chef_run, nvidia_enabled: true)
      chef_run.find_resource('fabric_manager', 'setup')
    end
    it "is not enabled" do
      expect(resource._fabric_manager_enabled).to eq(false)
    end
  end

  context 'when not on arm' do
    cached(:chef_run) do
      allow_any_instance_of(Object).to receive(:arm_instance?).and_return(false)
      ChefSpec::SoloRunner.new(step_into: ['fabric_manager'])
    end

    context 'when nvidia enabled' do
      cached(:resource) do
        ConvergeFabricManager.setup(chef_run, nvidia_enabled: true)
        chef_run.find_resource('fabric_manager', 'setup')
      end

      it "is enabled" do
        expect(resource._fabric_manager_enabled).to eq(true)
      end
    end

    context 'when nvidia not enabled' do
      cached(:resource) do
        ConvergeFabricManager.setup(chef_run, nvidia_enabled: false)
        chef_run.find_resource('fabric_manager', 'setup')
      end

      it "is not enabled" do
        expect(resource._fabric_manager_enabled).to eq(false)
      end
    end
  end
end

describe 'fabric_manager:setup' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:fabric_manager_package) { 'nvidia-fabricmanager' }

      context 'when fabric manager is to install' do
        cached(:chef_run) do
          stubs_for_resource('fabric_manager') do |res|
            allow(res).to receive(:_fabric_manager_enabled).and_return(true)
            allow(res).to receive(:fabric_manager_installed?).and_return(false)
          end
          runner = runner(platform: platform, version: version, step_into: ['fabric_manager'])
          ConvergeFabricManager.setup(runner)
        end
        cached(:node) { chef_run.node }

        it 'sets up fabric manager' do
          is_expected.to setup_fabric_manager('setup')
        end

        it 'installs fabric manager package from nvidia repo' do
          is_expected.to install_package(fabric_manager_package)
            .with(retries: 3)
            .with(retry_delay: 5)
        end

        it 'locks the package version' do
          if %w(ubuntu).include?(platform)
            is_expected.to run_execute("apt-mark hold #{fabric_manager_package}")
              .with(retries: 3)
              .with(retry_delay: 5)
          else
            is_expected.to install_package('yum-plugin-versionlock')
            is_expected.to run_execute("yum versionlock #{fabric_manager_package}")
              .with(retries: 3)
              .with(retry_delay: 5)
          end
        end
      end

      context 'when fabric manager is already installed (e.g. DLAMI)' do
        cached(:chef_run) do
          stubs_for_resource('fabric_manager') do |res|
            allow(res).to receive(:_fabric_manager_enabled).and_return(true)
            allow(res).to receive(:fabric_manager_installed?).and_return(true)
          end
          runner = runner(platform: platform, version: version, step_into: ['fabric_manager'])
          ConvergeFabricManager.setup(runner)
        end
        cached(:node) { chef_run.node }

        it 'skips the install when fabric manager is already present' do
          is_expected.not_to install_package(fabric_manager_package)
        end
      end
    end
  end
end

describe 'fabric_manager:configure' do
  cached(:fabric_manager_service) { 'nvidia-fabricmanager' }
  [true, false].each do |is_gb200|
    for_all_oses do |platform, version|
      context "on #{platform}#{version} on #{is_gb200} gb200 node" do
        cached(:fabric_manager_package) { 'nvidia-fabricmanager' }

        context('when fabric manager is required (multiple GPUs with bridges)') do
          cached(:chef_run) do
            stubs_for_provider('fabric_manager') do |res|
              allow(res).to receive(:get_pci_device_count).with('10de', '', '0302').and_return(8)
              allow(res).to receive(:get_pci_device_count).with('10de', '', '0680').and_return(6)
              allow(res).to receive(:get_pci_device_count).with('15b3', '', '0207').and_return(0)
              allow(res).to receive(:get_pci_device_count).with('10de', '2941').and_return(is_gb200 ? 2 : 0)
            end
            runner = runner(platform: platform, version: version, step_into: ['fabric_manager'])
            ConvergeFabricManager.configure(runner)
          end

          it 'configures fabric manager' do
            is_expected.to configure_fabric_manager('configure')
          end

          if is_gb200
            it 'does not start nvidia-fabricmanager service' do
              is_expected.not_to start_service(fabric_manager_service)
            end
          else
            it 'starts nvidia-fabricmanager service' do
              is_expected.to start_service(fabric_manager_service)
                .with_action(%i(start enable))
                .with_supports({ status: true })
            end
          end
        end

        context('when fabric manager is not required (single GPU or no bridges)') do
          cached(:chef_run) do
            stubs_for_provider('fabric_manager[configure]') do |res|
              allow(res).to receive(:get_pci_device_count).with('10de', '', '0302').and_return(1)
              allow(res).to receive(:get_pci_device_count).with('10de', '', '0680').and_return(0)
              allow(res).to receive(:get_pci_device_count).with('15b3', '', '0207').and_return(0)
              allow(res).to receive(:get_pci_device_count).with('10de', '2941').and_return(0)
            end
            runner = runner(platform: platform, version: version, step_into: ['fabric_manager'])
            ConvergeFabricManager.configure(runner)
          end

          it "doesn't start nvidia-fabricmanager service" do
            is_expected.not_to start_service(fabric_manager_service)
          end
        end
      end
    end
  end
end

describe 'fabric_manager:enable_fabric_manager?' do
  cached(:fabric_manager_service) { 'nvidia-fabricmanager' }
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      context 'when multiple GPUs with NVSwitches' do
        cached(:chef_run) do
          stubs_for_provider('fabric_manager') do |res|
            allow(res).to receive(:get_pci_device_count).with('10de', '', '0302').and_return(8)
            allow(res).to receive(:get_pci_device_count).with('10de', '', '0680').and_return(6)
            allow(res).to receive(:get_pci_device_count).with('15b3', '', '0207').and_return(0)
            allow(res).to receive(:get_pci_device_count).with('10de', '2941').and_return(0)
          end
          runner = runner(platform: platform, version: version, step_into: ['fabric_manager'])
          ConvergeFabricManager.configure(runner)
        end

        it 'enables fabric manager service' do
          is_expected.to start_service(fabric_manager_service)
        end
      end

      context 'when single GPU' do
        cached(:chef_run) do
          stubs_for_provider('fabric_manager') do |res|
            allow(res).to receive(:get_pci_device_count).with('10de', '', '0302').and_return(1)
            allow(res).to receive(:get_pci_device_count).with('10de', '', '0680').and_return(0)
            allow(res).to receive(:get_pci_device_count).with('15b3', '', '0207').and_return(0)
            allow(res).to receive(:get_pci_device_count).with('10de', '2941').and_return(0)
          end
          runner = runner(platform: platform, version: version, step_into: ['fabric_manager'])
          ConvergeFabricManager.configure(runner)
        end

        it 'does not enable fabric manager service' do
          is_expected.not_to start_service(fabric_manager_service)
        end
      end
    end
  end
end
