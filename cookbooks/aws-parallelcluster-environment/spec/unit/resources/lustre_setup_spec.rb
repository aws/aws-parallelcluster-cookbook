require 'spec_helper'

class Lustre
  def self.setup(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-environment') do
      lustre 'setup' do
        action :setup
      end
    end
  end

  def self.nothing(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-environment') do
      # This is a way to load the resource code and unit test function defined on it
      lustre 'nothing' do
        action :nothing
      end
    end
  end
end

describe 'lustre:setup' do
  context "on amazon2" do
    cached(:chef_run) do
      runner = runner(
        platform: 'amazon', version: '2',
        step_into: ['lustre']
      )
      Lustre.setup(runner)
    end

    it 'installs lustre2.10 extra topic' do
      is_expected.to install_alinux_extras_topic("lustre")
    end
  end

  [%w(redhat RHEL), ["rocky", "Rocky Linux"]].each do |platform, platform_string|
    context "on #{platform} lower than 8.2" do
      cached(:chef_run) do
        runner = runner(
          platform: platform, version: '8',
          step_into: ['lustre']
        ) do |node|
          node.automatic['platform_version'] = "8.1"
          node.override['cluster']['kernel_release'] = "4.18.0-147.9.1.el8"
        end
        Lustre.setup(runner)
      end

      it 'can not install lustre' do
        expect { chef_run }.to(raise_error do |error|
          expect(error).to be_a(Exception)
          expect(error.message).to include("FSx for Lustre is not supported in this #{platform_string} version 8.1, supported versions are >= 8.2")
        end)
      end
    end

    [%w(8.7 4.18.0-425.3.1.el8.x86_64), %w(8.7 4.18.0-425.13.1.el8_7.x86_64)].each do |platform_version, kernel_version|
      context "on #{platform} #{platform_version} with kernel #{kernel_version}" do
        cached(:chef_run) do
          runner = runner(
            platform: platform, version: '8',
            step_into: ['lustre']
          ) do |node|
            node.automatic['platform_version'] = platform_version
            node.override['cluster']['kernel_release'] = kernel_version
          end
          Lustre.setup(runner)
        end

        it 'can not install lustre' do
          expect { chef_run }.to(raise_error do |error|
            expect(error).to be_a(Exception)
            expect(error.message).to include("FSx for Lustre is not supported in kernel version #{kernel_version} of #{platform_string} #{platform_version}, please update the kernel version")
          end)
        end
      end
    end

    [%w(193 2), %w(240 3), %w(305 4), %w(348 5), %w(372 6), %w(425 7), %w(477 8), %w(513 9)].each do |kernel_patch, minor_version|
      context "on #{platform} with kernel from 4.18.0-#{kernel_patch}.3.1.el8 supporting lustre" do
        cached(:chef_run) do
          runner = runner(
            platform: platform, version: '8',
            step_into: ['lustre']
          ) do |node|
            node.automatic['platform_version'] = "8.#{minor_version}"
            node.override['cluster']['kernel_release'] = "4.18.0-#{kernel_patch}.9.1.el8"
          end
          Lustre.setup(runner)
        end

        it 'installs lustre packages from repository and installs kernel module lnet' do
          is_expected.to create_yum_repository("aws-fsx")
            .with(baseurl: "https://fsx-lustre-client-repo.s3.amazonaws.com/el/8.#{minor_version}/$basearch")
            .with(gpgkey: 'https://fsx-lustre-client-repo-public-keys.s3.amazonaws.com/fsx-rpm-public-key.asc')
            .with(retries: 3)
            .with(retry_delay: 5)

          is_expected.to run_execute('yum-config-manager_skip_if_unavail')
            .with(command: "yum-config-manager --setopt=\*.skip_if_unavailable=1 --save")

          is_expected.to install_package(%w(kmod-lustre-client lustre-client dracut))
            .with(retries: 3)
            .with(retry_delay: 5)

          is_expected.to install_kernel_module("lnet")
        end
      end
    end
  end

  for_oses([
     %w(ubuntu 20.04),
  ]) do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = runner(
          platform: platform, version: version,
          step_into: ['lustre']
        ) do |node|
          node.override['cluster']['kernel_release'] = 'kernel_release'
        end
        Lustre.setup(runner)
      end

      it 'installs lustre packages from repository and installs kernel module lnet' do
        is_expected.to add_apt_repository('fsxlustreclientrepo')
          .with(uri: 'https://fsx-lustre-client-repo.s3.amazonaws.com/ubuntu')
          .with(components: %w(main))
          .with(key: ["https://fsx-lustre-client-repo-public-keys.s3.amazonaws.com/fsx-ubuntu-public-key.asc"])
          .with(retries: 3)
          .with(retry_delay: 5)

        is_expected.to periodic_apt_update('')

        is_expected.to install_package(%w(lustre-client-modules-kernel_release lustre-client-modules-aws initramfs-tools))
          .with(retries: 3)
          .with(retry_delay: 5)

        is_expected.to install_kernel_module("lnet")
      end
    end
  end
end
