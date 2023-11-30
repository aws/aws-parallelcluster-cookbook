require 'spec_helper'

class ConvergeInstallPackages
  def self.setup(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-platform') do
      install_packages 'setup' do
        action :setup
      end
    end
  end
end

describe 'install_packages:setup' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:default_packages) { %w(package1 package2) }
      cached(:kernel_release) { 'kernel_release.x86_64' }
      cached(:kernel_source_package) { 'kernel_source_package' }
      cached(:kernel_source_package_version) { 'kernel_source_package_version' }
      cached(:chef_run) do
        stubs_for_resource('install_packages') do |res|
          allow(res).to receive(:default_packages).and_return(default_packages)
        end
        runner = runner(platform: platform, version: version, step_into: ['install_packages']) do |node|
          node.automatic['kernel']['release'] = kernel_release
        end
        ConvergeInstallPackages.setup(runner)
      end
      cached(:node) { chef_run.node }

      it 'sets up node packages' do
        is_expected.to setup_install_packages('setup')
        is_expected.to install_install_packages('default')
      end

      if %w(amazon centos redhat rocky).include?(platform)
        it 'installs default packages' do
          is_expected.to install_package(default_packages)
            .with(retries: 10)
            .with(retry_delay: 5)
            .with(flush_cache: { before: true })
        end

        if platform == 'rocky'
          it 'installs kernel source' do
            is_expected.to run_bash('Install kernel source')
              .with(user: 'root')
              .with_code(/set -e/)
              .with_code(/dnf install -y #{kernel_source_package}-#{kernel_source_package_version} --releasever #{platform}/)
              .with_code(/dnf clean all/)
          end
        else
          it 'installs kernel source' do
            is_expected.to install_package("install kernel packages")
              .with(package_name: 'kernel-devel')
              .with(version: 'kernel_release')
              .with(retries: 3)
              .with(retry_delay: 5)
          end
        end

        if platform == 'amazon'
          it 'installs extra packages' do
            is_expected.to install_alinux_extras_topic('R3.4')
          end
        end

      elsif platform == 'ubuntu'
        it 'installs base packages' do
          is_expected.to install_package(default_packages)
            .with(retries: 10)
            .with(retry_delay: 5)
        end

        it 'installs kernel source' do
          is_expected.to install_package("install kernel packages")
            .with(package_name: "linux-headers-#{kernel_release}")
            .with(retries: 3)
            .with(retry_delay: 5)
        end

      else
        pending "Implement for #{platform}"
      end
    end
  end
end
