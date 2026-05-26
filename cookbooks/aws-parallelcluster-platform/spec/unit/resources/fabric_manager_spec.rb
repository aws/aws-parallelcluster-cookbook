require 'spec_helper'

class ConvergeFabricManager
  def self.setup(chef_run, nvidia_driver_version: nil, nvidia_enabled: nil)
    chef_run.converge_dsl('aws-parallelcluster-platform') do
      fabric_manager 'setup' do
        nvidia_enabled nvidia_enabled
        nvidia_driver_version nvidia_driver_version
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

describe 'fabric_manager:_nvidia_driver_version' do
  cached(:nvidia_driver_attribute) { 'nvidia_driver_attribute' }
  cached(:nvidia_driver_property) { 'nvidia_driver_property' }
  cached(:chef_run) do
    ChefSpec::SoloRunner.new(step_into: ['fabric_manager']) do |node|
      node.override['cluster']['nvidia']['driver_version'] = nvidia_driver_attribute
    end
  end

  context 'when nvidia driver property is set' do
    cached(:resource) do
      ConvergeFabricManager.setup(chef_run, nvidia_driver_version: nvidia_driver_property)
      chef_run.find_resource('fabric_manager', 'setup')
    end

    it 'takes the value from nvidia driver property' do
      expect(resource._nvidia_driver_version).to eq(nvidia_driver_property)
    end
  end

  context 'when nvidia driver property is not set' do
    cached(:resource) do
      ConvergeFabricManager.setup(chef_run)
      chef_run.find_resource('fabric_manager', 'setup')
    end

    it 'takes the value from nvidia driver attribute' do
      expect(resource._nvidia_driver_version).to eq(nvidia_driver_attribute)
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
  cached(:nvidia_driver_version) { 'nvidia_driver_version' }
  cached(:aws_region) { 'test_region' }

  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:fabric_manager_version) { nvidia_driver_version }
      cached(:fabric_manager_package) { 'nvidia-fabricmanager' }

      context 'when fabric manager is to install' do
        cached(:chef_run) do
          stubs_for_resource('fabric_manager') do |res|
            allow(res).to receive(:_fabric_manager_enabled).and_return(true)
          end
          runner = runner(platform: platform, version: version, step_into: ['fabric_manager'])
          ConvergeFabricManager.setup(runner, nvidia_driver_version: nvidia_driver_version)
        end
        cached(:node) { chef_run.node }

        it 'sets up fabric manager' do
          is_expected.to setup_fabric_manager('setup')
        end

        it 'dumps node attributes' do
          expect(node['cluster']['nvidia']['fabricmanager']['package']).to eq(fabric_manager_package)
          expect(node['cluster']['nvidia']['fabricmanager']['version']).to eq(fabric_manager_version)
          is_expected.to write_node_attributes('dump node attributes')
        end

        if platform == 'ubuntu'
          it 'installs fabric manager for ubuntu' do
            is_expected.to run_bash('install_fabricmanager_for_ubuntu')
              .with_retries(3)
              .with_retry_delay(5)
              .with_code(/dpkg -i #{fabric_manager_package}-#{fabric_manager_version}.deb && apt-mark hold #{fabric_manager_package}/)
          end
        else
          it 'installs yum-plugin-versionlock' do
            is_expected.to install_package('yum-plugin-versionlock')
          end

          it 'installs fabric manager' do
            is_expected.to run_bash("Install #{fabric_manager_package}")
              .with(user: 'root')
              .with_retries(3)
              .with_retry_delay(5)
              .with_code(/yum install -y #{fabric_manager_package}-#{fabric_manager_version}.rpm/)
          end
        end
      end
    end
  end
end

describe 'fabric_manager:configure' do
  cached(:nvidia_driver_version) { 'nvidia_driver_version' }
  cached(:fabric_manager_service) { 'nvidia-fabricmanager' }
  [true, false].each do |is_gb200|
    for_all_oses do |platform, version|
      context "on #{platform}#{version} on #{is_gb200} gb200 node" do
        cached(:fabric_manager_package) { 'nvidia-fabricmanager' }
        cached(:fabric_manager_version) { nvidia_driver_version }

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

# Tests for the NVIDIA library helper nvidia_package_url as exercised
# through fabric_manager URL construction.
#
# Default S3 path:  {base_url}/{platform}/{filename}
# Public repo path: {base_url}/{platform}/{arch}/{filename}
describe 'fabric_manager_url construction' do
  FM_S3_ARTIFACTS_URL = 'https://REGION-aws-parallelcluster.s3.REGION.AWS_DOMAIN'.freeze
  FM_S3_BASE_URL = "#{FM_S3_ARTIFACTS_URL}/dependencies/nvidia_fabric".freeze
  FM_PUBLIC_BASE_URL = 'https://fake-public.example.DOMAIN/compute/cuda/repos'.freeze
  FM_DRIVER_VERSION = '999.99.99'.freeze

  PLATFORM_DIRS_FM = {
    'amazon2023' => 'rhel9', # FM AL2023 partial sets platform to 'rhel9'
    'ubuntu22.04' => 'ubuntu2204',
    'ubuntu24.04' => 'ubuntu2404',
    'redhat8' => 'rhel8',
    'redhat9' => 'rhel9',
    'rocky8' => 'rhel8',
    'rocky9' => 'rhel9',
  }.freeze

  for_all_oses do |platform, version|
    debian = (platform == 'ubuntu')
    ext = debian ? 'deb' : 'rpm'
    package_join = debian ? '_' : '-' # filename joiner between package and version
    arch_join = debian ? '_' : '.' # joiner between version-release and arch
    expected_platform = PLATFORM_DIRS_FM["#{platform}#{version}"]

    [false, true].each do |arm|
      arch_suffix = if debian
                      arm ? 'arm64' : 'amd64'
                    else
                      arm ? 'aarch64' : 'x86_64'
                    end
      package_filename = "nvidia-fabricmanager#{package_join}#{FM_DRIVER_VERSION}-1#{arch_join}#{arch_suffix}.#{ext}"

      [
        ['default S3 base_url',
         FM_S3_BASE_URL,
         "#{FM_S3_BASE_URL}/#{expected_platform}/#{package_filename}"],
        ['overridden public base_url',
         FM_PUBLIC_BASE_URL,
         "#{FM_PUBLIC_BASE_URL}/#{expected_platform}/#{arm ? 'sbsa' : 'x86_64'}/#{package_filename}"],
      ].each do |scenario, base_url, expected_source|
        context "on #{platform}#{version} #{arm ? 'ARM' : 'x86_64'} with #{scenario}" do
          cached(:chef_run) do
            allow_any_instance_of(Object).to receive(:arm_instance?).and_return(arm)
            runner(platform: platform, version: version, step_into: ['fabric_manager']) do |node|
              node.override['cluster']['artifacts_s3_url'] = FM_S3_ARTIFACTS_URL
              node.override['cluster']['nvidia']['fabricmanager']['base_url'] = base_url
              node.override['cluster']['nvidia']['driver_version'] = FM_DRIVER_VERSION
            end
          end
          cached(:resource) do
            ConvergeFabricManager.setup(chef_run, nvidia_enabled: true)
            chef_run.find_resource('fabric_manager', 'setup')
          end

          it 'builds the expected URL' do
            expect(resource.fabric_manager_url).to eq(expected_source)
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
