require 'spec_helper'

class ConvergeNvidiaDcgm
  def self.setup(chef_run, nvidia_enabled: nil)
    chef_run.converge_dsl('aws-parallelcluster-platform') do
      nvidia_dcgm 'setup' do
        nvidia_enabled nvidia_enabled
        action :setup
      end
    end
  end
end

describe 'nvidia_dcgm:_nvidia_enabled' do
  context 'when nvidia enabled property is set' do
    cached(:chef_run) do
      stubs_for_resource('nvidia_dcgm') do |res|
        allow(res).to receive(:dcgmi_installed?).and_return(false)
      end
      ChefSpec::SoloRunner.new(step_into: ['nvidia_dcgm']) do |node|
        node.override['cluster']['nvidia']['enabled'] = false
      end
    end
    cached(:resource) do
      ConvergeNvidiaDcgm.setup(chef_run, nvidia_enabled: true)
      chef_run.find_resource('nvidia_dcgm', 'setup')
    end

    it "takes precedence over node['cluster']['nvidia']['enabled'] attribute" do
      expect(resource._nvidia_enabled).to eq(true)
    end
  end

  context 'when nvidia enabled property is not set' do
    context "and node['cluster']['nvidia']['enabled'] is true" do
      cached(:chef_run) do
        stubs_for_resource('nvidia_dcgm') do |res|
          allow(res).to receive(:dcgmi_installed?).and_return(false)
        end
        ChefSpec::SoloRunner.new(step_into: ['nvidia_dcgm']) do |node|
          node.override['cluster']['nvidia']['enabled'] = true
        end
      end
      cached(:resource) do
        ConvergeNvidiaDcgm.setup(chef_run)
        chef_run.find_resource('nvidia_dcgm', 'setup')
      end
      it "is true" do
        expect(resource._nvidia_enabled).to eq(true)
      end
    end

    context "and node['cluster']['nvidia']['enabled'] is yes" do
      cached(:chef_run) do
        stubs_for_resource('nvidia_dcgm') do |res|
          allow(res).to receive(:dcgmi_installed?).and_return(false)
        end
        ChefSpec::SoloRunner.new(step_into: ['nvidia_dcgm']) do |node|
          node.override['cluster']['nvidia']['enabled'] = 'yes'
        end
      end
      cached(:resource) do
        ConvergeNvidiaDcgm.setup(chef_run)
        chef_run.find_resource('nvidia_dcgm', 'setup')
      end
      it "is true" do
        expect(resource._nvidia_enabled).to eq(true)
      end
    end

    context "and node['cluster']['nvidia']['enabled'] is not yes or true" do
      cached(:chef_run) do
        stubs_for_resource('nvidia_dcgm') do |res|
          allow(res).to receive(:dcgmi_installed?).and_return(false)
        end
        ChefSpec::SoloRunner.new(step_into: ['nvidia_dcgm']) do |node|
          node.override['cluster']['nvidia']['enabled'] = 'any'
        end
      end
      cached(:resource) do
        ConvergeNvidiaDcgm.setup(chef_run)
        chef_run.find_resource('nvidia_dcgm', 'setup')
      end
      it "is false" do
        expect(resource._nvidia_enabled).to eq(false)
      end
    end
  end
end

describe 'nvidia_dcgm:_nvidia_dcgm_enabled' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:expected_platform) do
        platforms = {
          'amazon2023' => 'amzn2023',
          'ubuntu22.04' => 'ubuntu2204',
          'ubuntu24.04' => 'ubuntu2404',
          'redhat8' => 'rhel8',
          'redhat9' => 'rhel9',
          'rocky8' => 'rhel8',
          'rocky9' => 'rhel9',
        }
        platforms["#{platform}#{version}"]
      end

      context 'when on arm and nvidia enabled' do
        cached(:resource) do
          allow_any_instance_of(Object).to receive(:arm_instance?).and_return(true)
          stubs_for_resource('nvidia_dcgm') do |res|
            allow(res).to receive(:dcgmi_installed?).and_return(false)
          end
          chef_run = runner(platform: platform, version: version, step_into: ['nvidia_dcgm'])
          ConvergeNvidiaDcgm.setup(chef_run, nvidia_enabled: true)
          chef_run.find_resource('nvidia_dcgm', 'setup')
        end
        it "is enabled" do
          expect(resource._nvidia_dcgm_enabled).to eq(true)
        end

        it "returns correct platform for download URL" do
          expect(resource.platform).to eq(expected_platform)
        end
      end

      context 'when not on arm and nvidia enabled' do
        cached(:resource) do
          allow_any_instance_of(Object).to receive(:arm_instance?).and_return(false)
          stubs_for_resource('nvidia_dcgm') do |res|
            allow(res).to receive(:dcgmi_installed?).and_return(false)
          end
          chef_run = runner(platform: platform, version: version, step_into: ['nvidia_dcgm'])
          ConvergeNvidiaDcgm.setup(chef_run, nvidia_enabled: true)
          chef_run.find_resource('nvidia_dcgm', 'setup')
        end

        it "is enabled" do
          expect(resource._nvidia_dcgm_enabled).to eq(true)
        end

        it "returns correct platform for download URL" do
          expect(resource.platform).to eq(expected_platform)
        end
      end

      context 'when not on arm and nvidia not enabled' do
        cached(:resource) do
          allow_any_instance_of(Object).to receive(:arm_instance?).and_return(false)
          stubs_for_resource('nvidia_dcgm') do |res|
            allow(res).to receive(:dcgmi_installed?).and_return(false)
          end
          chef_run = runner(platform: platform, version: version, step_into: ['nvidia_dcgm'])
          ConvergeNvidiaDcgm.setup(chef_run, nvidia_enabled: false)
          chef_run.find_resource('nvidia_dcgm', 'setup')
        end

        it "is not enabled" do
          expect(resource._nvidia_dcgm_enabled).to eq(false)
        end
      end
    end
  end
end

describe 'nvidia_dcgm:setup' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      context 'when nvidia not enabled' do
        cached(:chef_run) do
          stubs_for_resource('nvidia_dcgm') do |res|
            allow(res).to receive(:_nvidia_enabled).and_return(false)
          end
          runner = runner(platform: platform, version: version, step_into: ['nvidia_dcgm'])
          ConvergeNvidiaDcgm.setup(runner)
        end
        cached(:node) { chef_run.node }

        it 'does not install datacenter gpu manager' do
          is_expected.not_to run_bash('Install datacenter-gpu-manager')
        end
      end

      context 'when nvidia enabled' do
        cached(:chef_run) do
          stubs_for_resource('nvidia_dcgm') do |res|
            allow(res).to receive(:_nvidia_enabled).and_return(true)
            allow(res).to receive(:dcgmi_installed?).and_return(false)
          end
          runner(platform: platform, version: version, step_into: ['nvidia_dcgm'])
        end

        context 'and it is an arm instance' do
          before do
            allow_any_instance_of(Object).to receive(:arm_instance?).and_return(true)
            ConvergeNvidiaDcgm.setup(chef_run)
          end

          it 'installs datacenter gpu manager' do
            is_expected.to run_bash('Install datacenter-gpu-manager-4-core')
            is_expected.to run_bash('Install datacenter-gpu-manager-4-cuda13')
          end
        end

        context 'and it is not an arm instance' do
          before do
            allow_any_instance_of(Object).to receive(:arm_instance?).and_return(false)
            ConvergeNvidiaDcgm.setup(chef_run)
          end

          it 'sets up nvidia_dcgm' do
            is_expected.to setup_nvidia_dcgm('setup')
          end

          # it 'installs datacenter gpu manager' do
          #   is_expected.to install_package('datacenter-gpu-manager')
          # end
        end
      end

      context 'when nvidia enabled and DCGM is already installed' do
        cached(:chef_run) do
          stubs_for_resource('nvidia_dcgm') do |res|
            allow(res).to receive(:_nvidia_enabled).and_return(true)
            allow(res).to receive(:dcgmi_installed?).and_return(true)
          end
          runner = runner(platform: platform, version: version, step_into: ['nvidia_dcgm'])
          ConvergeNvidiaDcgm.setup(runner)
        end

        it 'does not install datacenter gpu manager' do
          is_expected.not_to run_bash('Install datacenter-gpu-manager-4-core')
          is_expected.not_to run_bash('Install datacenter-gpu-manager-4-cuda13')
          is_expected.not_to run_bash('Install datacenter-gpu-manager')
        end
      end
    end
  end
end

# Tests for the NVIDIA library helpers nvidia_package_url and nvidia_repo_arch
# as exercised through DCGM download URL construction.
#
# Helpers verified:
#   - nvidia_package_url(base_url, platform, filename): builds {base_url}/{platform}/{filename}
#     for the default S3 mirror and {base_url}/{platform}/{arch}/{filename} for the public
#     NVIDIA repo.
#   - nvidia_repo_arch: returns 'sbsa' for ARM and 'x86_64' for non-ARM.
describe 'nvidia_dcgm download URL construction' do
  S3_ARTIFACTS_URL = 'https://REGION-aws-parallelcluster.s3.REGION.AWS_DOMAIN'.freeze
  S3_DCGM_BASE_URL = "#{S3_ARTIFACTS_URL}/dependencies/nvidia_dcgm".freeze
  PUBLIC_NVIDIA_BASE_URL = 'https://fake-public.example.DOMAIN/compute/cuda/repos'.freeze
  DCGM_VERSION = '9.9.9-1'.freeze # any non-3.x version exercises the 4-core / 4-cudaXX package path

  PLATFORM_DIRS = {
    'amazon2023' => 'amzn2023',
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
    package_join = debian ? '_' : '-'
    arch_join = debian ? '_' : '.'
    expected_platform = PLATFORM_DIRS["#{platform}#{version}"]
    expected_filename = "datacenter-gpu-manager-4-core-#{DCGM_VERSION}.#{ext}"

    [false, true].each do |arm|
      arch_suffix = if debian
                      arm ? 'arm64' : 'amd64'
                    else
                      arm ? 'aarch64' : 'x86_64'
                    end
      package_filename = "datacenter-gpu-manager-4-core#{package_join}#{DCGM_VERSION}#{arch_join}#{arch_suffix}.#{ext}"

      [
        ['default S3 base_url',
         S3_DCGM_BASE_URL,
         "#{S3_DCGM_BASE_URL}/#{expected_platform}/#{package_filename}"],
        ['overridden public base_url',
         PUBLIC_NVIDIA_BASE_URL,
         "#{PUBLIC_NVIDIA_BASE_URL}/#{expected_platform}/#{arm ? 'sbsa' : 'x86_64'}/#{package_filename}"],
      ].each do |scenario, base_url, expected_source|
        context "on #{platform}#{version} #{arm ? 'ARM' : 'x86_64'} with #{scenario}" do
          cached(:chef_run) do
            stubs_for_resource('nvidia_dcgm') do |res|
              allow(res).to receive(:_nvidia_dcgm_enabled).and_return(true)
              allow(res).to receive(:dcgmi_installed?).and_return(false)
            end
            allow_any_instance_of(Object).to receive(:arm_instance?).and_return(arm)
            runner = runner(platform: platform, version: version, step_into: ['nvidia_dcgm']) do |node|
              node.override['cluster']['artifacts_s3_url'] = S3_ARTIFACTS_URL
              node.override['cluster']['nvidia']['dcgm_base_url'] = base_url
              node.override['cluster']['nvidia']['dcgm_version'] = DCGM_VERSION
            end
            ConvergeNvidiaDcgm.setup(runner, nvidia_enabled: true)
          end

          it 'downloads from the expected URL' do
            expect(chef_run).to create_if_missing_remote_file(
              "#{chef_run.node['cluster']['sources_dir']}/#{expected_filename}"
            ).with(source: expected_source)
          end
        end
      end
    end
  end
end
