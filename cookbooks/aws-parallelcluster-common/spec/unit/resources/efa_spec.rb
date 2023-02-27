require 'spec_helper'

# Converge efa:setup
def setup(chef_run)
  chef_run.converge_dsl do
    efa 'setup' do
      action :setup
    end
  end
end

# Converge efa:configure
def configure(chef_run)
  chef_run.converge_dsl do
    efa 'configure' do
      action :configure
    end
  end
end

# Mock Networking.efa_installed?
def mock_efa_installed(installed)
  allow(Networking).to receive(:efa_installed?).and_return(installed)
end

# Mock Networking.efa_supported?
def mock_efa_supported(supported)
  allow(Networking).to receive(:efa_supported?).and_return(supported)
end

# parallelcluster default source dir defined in attributes
source_dir = '/opt/parallelcluster/sources'

describe 'efa:setup' do
  before do
    # This is required before mocking existence of specific files
    allow(File).to receive(:exist?).and_call_original
  end

  [
    %w(amazon 2),
    # The only Centos7 version supported by ChefSpec
    # See the complete list here: https://github.com/chefspec/fauxhai/blob/main/PLATFORMS.md
    ['centos', '7.8.2003'],
    ['ubuntu', '18.04'],
    ['ubuntu', '20.04'],
    %w(redhat 8),
  ].each do |platform, version|
    context "on #{platform}#{version}" do
      let(:chef_run) do
        ChefSpec::Runner.new(
          # Create a runner for the given platform/version
          platform: platform, version: version,
          # Allow the runner to execute efa resource actions
          step_into: ['efa']
        ) do |node|
          # override node['cluster']['efa']['installer_version'] attribute
          node.override['cluster']['efa']['installer_version'] = 'version'
          node.override['cluster']['platform_version'] = "8.7"
        end
      end
      let(:node) { chef_run.node }

      context 'when efa installed' do
        before do
          mock_efa_installed(true)
        end

        context 'and installer tarball does not exist' do
          before do
            allow(::File).to receive(:exist?).with("/opt/parallelcluster/sources/aws-efa-installer.tar.gz").and_return(false)
          end

          it 'exits with warning' do
            expect(Chef::Log).to receive(:warn).with("Existing EFA version differs from the one shipped with ParallelCluster. Skipping ParallelCluster EFA installation and configuration.")
            setup(chef_run)
          end
        end

        context 'and installer tarball exists' do
          before do
            allow(::File).to receive(:exist?).with("#{source_dir}/aws-efa-installer.tar.gz").and_return(true)
            mock_efa_supported(true)
          end

          it 'installs EFA' do
            # the expectation must be declared before running the action
            expect(Chef::Log).not_to receive(:warn)
            setup(chef_run)

            is_expected.not_to remove_package(%w(openmpi-devel openmpi))
            is_expected.to update_package_repos('update package repos')
            is_expected.to install_package("environment-modules")
            is_expected.to create_if_missing_remote_file("#{source_dir}/aws-efa-installer.tar.gz")
            is_expected.not_to run_bash('install efa')
          end
        end
      end

      context 'when efa not installed' do
        before do
          mock_efa_installed(false)
          expect(Chef::Log).not_to receive(:warn)
        end

        context 'when efa supported' do
          before do
            mock_efa_supported(true)
          end

          it 'installs EFA without skipping kmod' do
            setup(chef_run)
            is_expected.to remove_package(platform == 'ubuntu' ? ['libopenmpi-dev'] : %w(openmpi-devel openmpi))
            is_expected.to update_package_repos('update package repos')
            is_expected.to install_package("environment-modules")
            is_expected.to create_if_missing_remote_file("#{source_dir}/aws-efa-installer.tar.gz")
            is_expected.to run_bash('install efa')
              .with(code: %(      set -e
      tar -xzf #{source_dir}/aws-efa-installer.tar.gz
      cd aws-efa-installer
      ./efa_installer.sh -y
      rm -rf /aws-efa-installer
))
          end
        end

        context 'when efa not supported' do
          before do
            mock_efa_supported(false)
          end

          it 'installs EFA skipping kmod' do
            setup(chef_run)
            is_expected.to remove_package(platform == 'ubuntu' ? ['libopenmpi-dev'] : %w(openmpi-devel openmpi))
            is_expected.to update_package_repos('update package repos')
            is_expected.to install_package("environment-modules")
            is_expected.to create_if_missing_remote_file("#{source_dir}/aws-efa-installer.tar.gz")
            is_expected.to run_bash('install efa')
              .with(code: %(      set -e
      tar -xzf #{source_dir}/aws-efa-installer.tar.gz
      cd aws-efa-installer
      ./efa_installer.sh -y -k
      rm -rf /aws-efa-installer
))
          end
        end
      end
    end
  end

  context 'when rhel version is older than 8.4' do
    let(:chef_run) do
      ChefSpec::Runner.new(
        # Create a runner for the given platform/version
        platform: "redhat",
        step_into: ['efa']
      ) do |node|
        # override node['cluster']['efa']['installer_version'] attribute
        node.override['cluster']['platform_version'] = "8.3"
      end
    end

    it "version" do
      setup(chef_run)
      is_expected.to write_log('EFA is not supported in this RHEL version 8.3, supported versions are >= 8.4').with_level(:warn)
      is_expected.not_to update_package_repos('update package repos')
    end
  end
end

describe 'efa:configure' do
  before do
    allow(File).to receive(:exist?).and_call_original
  end

  [
    %w(amazon 2),
    ['centos', '7.8.2003'],
    %w(redhat 8),
  ].each do |platform, version|
    context "on #{platform}#{version}" do
      let(:chef_run) do
        ChefSpec::Runner.new(
          platform: platform, version: version,
          step_into: ['efa']
        )
      end

      it 'does nothing' do
        configure(chef_run)
        is_expected.not_to apply_sysctl('kernel.yama.ptrace_scope')
      end
    end
  end

  [
    ['ubuntu', '18.04'],
    ['ubuntu', '20.04'],
  ].each do |platform, version|
    context "on #{platform}#{version}" do
      let(:chef_run) do
        ChefSpec::Runner.new(
          platform: platform, version: version,
          step_into: ['efa']
        )
      end

      context 'when efa enabled on compute node' do
        before do
          chef_run.node.override['cluster']['enable_efa'] = 'compute'
          chef_run.node.override['cluster']['node_type'] = 'ComputeFleet'
        end

        it 'disables ptrace protection on compute nodes' do
          configure(chef_run)
          is_expected.to apply_sysctl('kernel.yama.ptrace_scope').with(value: "0")
        end
      end

      context 'when efa not enabled on compute node' do
        before do
          chef_run.node.override['cluster']['enable_efa'] = 'other'
          chef_run.node.override['cluster']['node_type'] = 'ComputeFleet'
        end

        it 'does not disable ptrace protection' do
          configure(chef_run)
          is_expected.not_to apply_sysctl('kernel.yama.ptrace_scope')
        end
      end

      context 'when it is not a compute node' do
        before do
          chef_run.node.override['cluster']['enable_efa'] = 'compute'
          chef_run.node.override['cluster']['node_type'] = 'other'
        end

        it 'does not disable ptrace protection' do
          configure(chef_run)
          is_expected.not_to apply_sysctl('kernel.yama.ptrace_scope')
        end
      end
    end
  end
end
