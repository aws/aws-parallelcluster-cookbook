require 'spec_helper'

class ConvergeInstallPackages
  def self.setup(chef_run)
    chef_run.converge_dsl do
      install_packages 'setup' do
        action :setup
      end
    end
  end
end

describe 'install_packages:setup' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:base_packages) { %w(package1 package2) }
      cached(:kernel_headers_pkg) { %w(kernel_header_pkg_1 kernel_header_pkg_2) }
      cached(:kernel_devel_pkg) { 'kernel_devel_package' }
      cached(:kernel_devel_pkg_version) { '3.10.0-1160.42.2.el7.x86_64' }
      cached(:amazon_extra_packages) { %w(amazon_extra_package1 amazon_extra_package2) }
      cached(:chef_run) do
        runner = ChefSpec::Runner.new(
          platform: platform, version: version,
          step_into: ['install_packages']
        ) do |node|
          node.override['cluster']['base_packages'] = base_packages
          node.override['cluster']['kernel_devel_pkg']['name'] = kernel_devel_pkg
          node.override['cluster']['kernel_devel_pkg']['version'] = kernel_devel_pkg_version
          node.override['cluster']['kernel_headers_pkg'] = kernel_headers_pkg
          node.override['cluster']['extra_packages'] = amazon_extra_packages
        end
        ConvergeInstallPackages.setup(runner)
      end
      cached(:node) { chef_run.node }

      if %w(amazon centos redhat).include?(platform)
        it 'installs base packages' do
          is_expected.to install_package(base_packages)
            .with(retries: 10)
            .with(retry_delay: 5)
            .with(flush_cache: { before: true })
        end

        it 'installs kernel source' do
          is_expected.to install_package("install kernel packages")
            .with(package_name: kernel_devel_pkg)
            .with(version: '3.10.0-1160.42.2.el7')
            .with(retries: 3)
            .with(retry_delay: 5)
        end

        if platform == 'amazon'
          it 'installs extra packages' do
            is_expected.to install_alinux_extras_topic('amazon_extra_package1')
            is_expected.to install_alinux_extras_topic('amazon_extra_package2')
          end
        end

      elsif platform == 'ubuntu'
        it 'installs base packages' do
          is_expected.to install_package(base_packages)
            .with(retries: 10)
            .with(retry_delay: 5)
        end

        it 'installs kernel source' do
          is_expected.to install_package("install kernel packages")
            .with(package_name: kernel_headers_pkg)
            .with(retries: 3)
            .with(retry_delay: 5)
        end

      else
        pending "Implement for #{platform}"
      end
    end
  end
end
