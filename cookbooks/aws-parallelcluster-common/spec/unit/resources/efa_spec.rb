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
  for_all_oses do |platform, version|
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

      context 'when efa installed' do
        before do
          mock_efa_installed(true)
        end

        context 'and installer tarball does not exist' do
          before do
            mock_file_exists('/opt/parallelcluster/sources/aws-efa-installer.tar.gz', false)
            setup(chef_run)
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
            mock_efa_supported(true)
            setup(chef_run)
          end

          it 'installs EFA' do
            is_expected.not_to write_log('efa installed')
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
        end

        context 'when efa supported' do
          before do
            mock_efa_supported(true)
            setup(chef_run)
          end

          it 'installs EFA without skipping kmod' do
            is_expected.not_to write_log('efa installed')
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
            setup(chef_run)
          end

          it 'installs EFA skipping kmod' do
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
    cached(:chef_run) do
      runner = ChefSpec::Runner.new(
        # Create a runner for the given platform/version
        platform: "redhat",
        step_into: ['efa']
      ) do |node|
        node.override['cluster']['platform_version'] = "8.3"
      end
      setup(runner)
    end

    it "version" do
      is_expected.to write_log('EFA is not supported in this RHEL version 8.3, supported versions are >= 8.4').with_level(:warn)
      is_expected.not_to update_package_repos('update package repos')
    end
  end
end

describe 'efa:configure' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      let(:chef_run) do
        ChefSpec::Runner.new(
          platform: platform, version: version,
          step_into: ['efa']
        )
      end

      if %w(amazon centos redhat).include?(platform)
        it 'does nothing' do
          configure(chef_run)
          is_expected.not_to apply_sysctl('kernel.yama.ptrace_scope')
        end

      elsif platform == 'ubuntu'
        context 'when efa enabled on compute node' do
          before do
            chef_run.node.override['cluster']['enable_efa'] = 'compute'
            chef_run.node.override['cluster']['node_type'] = 'ComputeFleet'
            configure(chef_run)
          end

          it 'disables ptrace protection on compute nodes' do
            is_expected.to apply_sysctl('kernel.yama.ptrace_scope').with(value: "0")
          end
        end

        context 'when efa not enabled on compute node' do
          before do
            chef_run.node.override['cluster']['enable_efa'] = 'other'
            chef_run.node.override['cluster']['node_type'] = 'ComputeFleet'
            configure(chef_run)
          end

          it 'does not disable ptrace protection' do
            is_expected.not_to apply_sysctl('kernel.yama.ptrace_scope')
          end
        end

        context 'when it is not a compute node' do
          before do
            chef_run.node.override['cluster']['enable_efa'] = 'compute'
            chef_run.node.override['cluster']['node_type'] = 'other'
            configure(chef_run)
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
