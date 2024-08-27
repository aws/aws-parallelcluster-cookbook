require 'spec_helper'

package_version = '3.4.1'
class ConvergeEnroot
  def self.setup(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-platform') do
      enroot 'setup' do
        action :setup
      end
    end
  end

  def self.configure(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-platform') do
      enroot 'configure' do
        action :configure
      end
    end
  end
end

describe 'enroot:package_version' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        allow_any_instance_of(Object).to receive(:nvidia_enabled?).and_return(false)
        runner = runner(platform: platform, version: version, step_into: ['enroot'])
        ConvergeEnroot.setup(runner)
      end
      cached(:resource) do
        chef_run.find_resource('enroot', 'setup')
      end

      it 'returns the expected enroot version' do
        expected_enroot_version = "3.4.1"
        expect(resource.package_version).to eq(expected_enroot_version)
      end
    end
  end
end

describe 'enroot:arch_suffix' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version} - arm" do
      cached(:chef_run) do
        allow_any_instance_of(Object).to receive(:nvidia_enabled?).and_return(false)
        runner = runner(platform: platform, version: version, step_into: ['enroot'])
        ConvergeEnroot.setup(runner)
      end
      cached(:resource) do
        chef_run.find_resource('enroot', 'setup')
      end

      context 'on arm instance' do
        cached(:expected_arch) do
          case platform
          when 'amazon', 'redhat', 'rocky'
            'aarch64'
          else
            'arm64'
          end
        end

        it 'returns arch value for arm architecture' do
          allow_any_instance_of(Object).to receive(:arm_instance?).and_return(true)
          expect(resource.arch_suffix).to eq(expected_arch)
        end
      end

      context 'not on arm instance' do
        cached(:expected_arch) do
          platform == 'ubuntu' ? 'amd64' : 'x86_64'
        end

        it 'returns arch value for arm architecture' do
          allow_any_instance_of(Object).to receive(:arm_instance?).and_return(false)
          expect(resource.arch_suffix).to eq(expected_arch)
        end
      end
    end
  end
end

describe 'enroot:setup' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      let(:chef_run) do
        runner(platform: platform, version: version, step_into: ['enroot']) do |node|
          node.override['cluster']['enroot']['version'] = package_version
        end
      end

      context 'when nvidia is enabled' do
        before do
          stubs_for_provider('enroot') do |resource|
            allow(resource).to receive(:nvidia_enabled?).and_return(true)
          end
        end

        context 'and enroot is installed' do
          before do
            ConvergeEnroot.setup(chef_run)
          end

          it 'installs Enroot' do
            is_expected.to run_bash('Install enroot')
          end
        end
      end

      context 'when nvidia is not enabled' do
        before do
          stubs_for_provider('enroot') do |resource|
            allow(resource).to receive(:nvidia_enabled?).and_return(false)
          end
        end

        context 'and enroot is installed' do
          before do
            ConvergeEnroot.setup(chef_run)
          end

          it 'does not install Enroot' do
            is_expected.not_to run_bash('Install enroot')
          end
        end
      end
    end
  end
end

describe 'enroot:configure' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      let(:chef_run) do
        runner(platform: platform, version: version, step_into: ['enroot'])
      end

      context 'when enroot is installed' do
        before do
          stubs_for_provider('enroot') do |resource|
            allow(resource).to receive(:enroot_installed).and_return(true)
          end
          ConvergeEnroot.configure(chef_run)
        end
        it 'run configure enroot script' do
          is_expected.to run_bash('Configure enroot')
            .with(retries: 3)
            .with(retry_delay: 5)
            .with(user: 'root')
        end
      end

      context 'when enroot is not installed' do
        before do
          stubs_for_provider('enroot') do |resource|
            allow(resource).to receive(:enroot_installed).and_return(false)
          end
          ConvergeEnroot.configure(chef_run)
        end

        it 'does not run configure enroot script' do
          is_expected.not_to run_bash('Configure enroot')
            .with(retries: 3)
            .with(retry_delay: 5)
            .with(user: 'root')
        end
      end
    end
  end
end
