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
end

describe 'aws-parallelcluster-platform::enroot:package_version' do
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

describe 'aws-parallelcluster-platform::enroot:enroot_installed' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      binary = '/usr/bin/enroot'
      [true, false].each do |binary_exist|
        context "when binary #{binary} does #{'not ' unless binary_exist}exist" do
          cached(:chef_run) do
            allow(File).to receive(:exist?).with(binary).and_return(binary_exist)
            runner = runner(platform: platform, version: version, step_into: ['enroot'])
            ConvergeEnroot.setup(runner)
          end

          cached(:resource) do
            chef_run.find_resource('enroot', 'setup')
          end

          expected_result = binary_exist

          it "returns #{expected_result}" do
            expect(resource.enroot_installed).to eq(expected_result)
          end
        end
      end
    end
  end
end

describe 'aws-parallelcluster-platform::enroot:arch_suffix' do
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

describe 'aws-parallelcluster-platform::enroot:setup' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:cluster_examples_dir) { '/path/to/cluster/examples/dir' }
      cached(:enroot_persistent_dir) { '/path/to/enroot/persistent/dir' }
      cached(:enroot_temporary_dir) { '/path/to/enroot/temporary/dir' }

      context "when enroot is already installed" do
        let(:chef_run) do
          stubs_for_resource('enroot') do |res|
            allow(res).to receive(:enroot_installed).and_return(true)
          end
          runner(platform: platform, version: version, step_into: ['enroot']) do |node|
            node.override['cluster']['enroot']['version'] = package_version
            node.override['cluster']['examples_dir'] = cluster_examples_dir
          end
        end

        before do
          ConvergeEnroot.setup(chef_run)
        end

        it 'does not install Enroot' do
          is_expected.not_to run_bash('Install enroot')
        end

        it 'does not create the Enroot configuration' do
          is_expected.not_to create_template("#{cluster_examples_dir}/enroot/enroot.conf")
        end
      end

      let(:chef_run) do
        stubs_for_resource('enroot') do |res|
          allow(res).to receive(:enroot_installed).and_return(false)
        end
        runner(platform: platform, version: version, step_into: ['enroot']) do |node|
          node.override['cluster']['enroot']['version'] = package_version
          node.override['cluster']['examples_dir'] = cluster_examples_dir
          node.override['cluster']['enroot']['persistent_dir'] = enroot_persistent_dir
          node.override['cluster']['enroot']['temporary_dir'] = enroot_temporary_dir
        end
      end

      before do
        ConvergeEnroot.setup(chef_run)
      end

      it 'installs Enroot' do
        is_expected.not_to run_bash('Install enroot')
      end

      it 'creates the Enroot example configuration' do
        is_expected.to create_template("#{cluster_examples_dir}/enroot/enroot.conf").with(
          source: 'enroot/enroot.conf.erb',
          owner: 'root',
          group: 'root',
          mode: '0644'
        )
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
