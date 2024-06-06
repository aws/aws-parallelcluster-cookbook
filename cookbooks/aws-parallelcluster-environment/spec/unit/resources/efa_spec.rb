require 'spec_helper'

# parallelcluster default source dir defined in attributes
source_dir = '/opt/parallelcluster/sources'
efa_version = '1.32.0'
efa_checksum = '5f7233760be57f6fee6de8c09acbfbf59238de848e06048dc54d156ef578fc66'

class ConvergeEfa
  def self.setup(chef_run, efa_version: nil, efa_checksum: nil)
    chef_run.converge_dsl('aws-parallelcluster-environment') do
      efa 'setup' do
        efa_version efa_version
        efa_checksum efa_checksum
        action :setup
      end
    end
  end

  # Converge efa:configure
  def self.configure(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-environment') do
      efa 'configure' do
        action :configure
      end
    end
  end
end

describe 'efa:property' do
  cached(:old_efa_version) { 'old_efa_version' }
  cached(:old_efa_checksum) { 'old_efa_checksum' }
  cached(:chef_run) do
    ChefSpec::SoloRunner.new(step_into: ['efa']) do |node|
      node.override['cluster']['efa']['version'] = old_efa_version
      node.override['cluster']['efa']['sha256'] = old_efa_checksum
    end
  end

  context 'when efa version and checksum property is overriden' do
    cached(:resource) do
      ConvergeEfa.setup(chef_run, efa_version: old_efa_version, efa_checksum: old_efa_checksum)
      chef_run.find_resource('efa', 'setup')
    end

    it 'takes the value from efa property' do
      expect(resource.efa_version).to eq(old_efa_version)
      expect(resource.efa_checksum).to eq(old_efa_checksum)
    end
  end
end

describe 'efa:setup' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:prerequisites) do
        if %(redhat rocky).include?(platform)
          %w(environment-modules libibverbs-utils librdmacm-utils rdma-core-devel)
        elsif platform == 'amazon'
          %w(environment-modules libibverbs-utils librdmacm-utils)
        else
          "environment-modules"
        end
      end
      let(:chef_run) do
        runner(platform: platform, version: version, step_into: ['efa']) do |node|
          if platform == 'redhat'; node.automatic['platform_version'] = "8.7" end
          node.override['cluster']['efa']['version'] = efa_version
          node.override['cluster']['efa']['sha256'] = efa_checksum
          node.override['cluster']['sources_dir'] = source_dir
        end
      end

      context 'when efa installed' do
        before do
          stubs_for_provider('efa') do |resource|
            allow(resource).to receive(:efa_installed?).and_return(true)
          end
        end

        context 'and installer tarball does not exist' do
          before do
            mock_file_exists("#{source_dir}/aws-efa-installer.tar.gz", false)
            ConvergeEfa.setup(chef_run)
          end

          it 'exits with warning' do
            is_expected.to write_log('efa installed')
              .with(message: 'Existing EFA version differs from the one shipped with ParallelCluster. Skipping ParallelCluster EFA installation and configuration.')
              .with(level: :warn)
          end
        end

        context 'and installer tarball exists' do
          before do
            mock_file_exists("#{source_dir}/aws-efa-installer.tar.gz", true)
            ConvergeEfa.setup(chef_run)
          end

          it 'installs EFA' do
            is_expected.not_to write_log('efa installed')
            is_expected.not_to remove_package(%w(openmpi-devel openmpi))
            is_expected.to update_package_repos('update package repos')
            is_expected.to install_package(prerequisites)
            is_expected.to create_if_missing_remote_file("#{source_dir}/aws-efa-installer.tar.gz")
            is_expected.not_to run_bash('install efa')
          end
        end
      end

      context 'when efa not installed' do
        before do
          stubs_for_provider('efa') do |resource|
            allow(resource).to receive(:efa_installed?).and_return(false)
          end
        end

        context 'when efa supported' do
          before do
            allow_any_instance_of(Object).to receive(:arm_instance?).and_return(false)
            ConvergeEfa.setup(chef_run)
          end

          it 'installs EFA without skipping kmod' do
            is_expected.to create_directory(source_dir)
            is_expected.to setup_efa('setup')
            is_expected.not_to write_log('efa installed')
            is_expected.to remove_package(platform == 'ubuntu' ? ['libopenmpi-dev'] : %w(openmpi-devel openmpi))
            is_expected.to update_package_repos('update package repos')
            is_expected.to install_package(prerequisites)
            is_expected.to create_if_missing_remote_file("#{source_dir}/aws-efa-installer.tar.gz")
              .with(source: "https://efa-installer.amazonaws.com/aws-efa-installer-#{efa_version}.tar.gz")
              .with(mode: '0644')
              .with(retries: 3)
              .with(retry_delay: 5)
              .with(checksum: efa_checksum)

            is_expected.to run_bash('install efa')
              .with(code: %(      set -e
      tar -xzf #{source_dir}/aws-efa-installer.tar.gz
      cd aws-efa-installer
      ./efa_installer.sh -y
      rm -rf #{source_dir}/aws-efa-installer
))
          end
        end
      end
    end
  end

  context 'when rhel version is older than 8.4' do
    cached(:chef_run) do
      runner = ChefSpec::Runner.new(
        # Create a runner for the given platform/version
        platform: "redhat",
        step_into: ['efa']
      ) do |node|
        node.automatic['platform_version'] = "8.3"
      end
      ConvergeEfa.setup(runner)
    end

    it "logs EFA not supported message" do
      is_expected.to write_log('EFA is not supported in this RHEL version 8.3, supported versions are >= 8.4').with_level(:warn)
    end

    it "doesn't install EFA kmod" do
      is_expected.to run_bash('install efa').with_code(%r{./efa_installer.sh -y -k})
    end
  end

  context 'when centos on arm' do
    cached(:chef_run) do
      runner = ChefSpec::Runner.new(
        platform: "centos", version: '7', step_into: ['efa']
      )
      allow_any_instance_of(Object).to receive(:arm_instance?).and_return(true)
      ConvergeEfa.setup(runner)
    end

    it "doesn't install EFA kmod" do
      is_expected.to run_bash('install efa').with_code(%r{./efa_installer.sh -y -k})
    end
  end
end

describe 'efa:configure' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      let(:chef_run) do
        runner(platform: platform, version: version, step_into: ['efa'])
      end

      if %w(amazon centos redhat rocky).include?(platform)
        it 'does nothing' do
          ConvergeEfa.configure(chef_run)
          is_expected.to configure_efa('configure')
          is_expected.to write_node_attributes('dump node attributes')
          is_expected.not_to apply_sysctl('kernel.yama.ptrace_scope')
        end

      elsif platform == 'ubuntu'
        context 'when efa enabled on compute node' do
          before do
            chef_run.node.override['cluster']['enable_efa'] = 'efa'
            chef_run.node.override['cluster']['node_type'] = 'ComputeFleet'
            ConvergeEfa.configure(chef_run)
          end
          it 'disables ptrace protection on compute nodes' do
            is_expected.to apply_sysctl('kernel.yama.ptrace_scope').with(value: "0")
          end
        end

        context 'when efa not enabled on compute node' do
          before do
            chef_run.node.override['cluster']['enable_efa'] = 'other'
            chef_run.node.override['cluster']['node_type'] = 'ComputeFleet'
            ConvergeEfa.configure(chef_run)
          end

          it 'does not disable ptrace protection' do
            is_expected.not_to apply_sysctl('kernel.yama.ptrace_scope')
          end
        end

        context 'when it is not a compute node' do
          before do
            chef_run.node.override['cluster']['enable_efa'] = 'efa'
            chef_run.node.override['cluster']['node_type'] = 'other'
            ConvergeEfa.configure(chef_run)
          end

          it 'does not disable ptrace protection' do
            is_expected.not_to apply_sysctl('kernel.yama.ptrace_scope')
          end
        end

      else
        pending "Implement for #{platform}"
      end
    end
  end
end
