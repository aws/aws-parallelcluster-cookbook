require 'spec_helper'

class Lustre
  def self.setup(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-environment') do
      lustre 'setup' do
        action :setup
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

  context "on centos 7.4 or lower" do
    cached(:chef_run) do
      runner = runner(
        platform: 'centos', version: '7',
        step_into: ['lustre']
      ) do |node|
        node.automatic['platform_version'] = "7.4"
      end
      Lustre.setup(runner)
    end

    it 'can not install lustre' do
      is_expected.to write_log("Unsupported version of Centos, 7.4, supported versions are >= 7.5")
        .with(level: :warn)
    end
  end

  context "on centos 7.5" do
    cached(:chef_run) do
      runner = runner(
        platform: 'centos', version: '7',
        step_into: ['lustre']
      ) do |node|
        node.automatic['platform_version'] = "7.5"
        node.override['cluster']['sources_dir'] = "srcdir"
      end
      Lustre.setup(runner)
    end

    it 'installs kmod-lustre-client from downloaded rpm' do
      is_expected.to create_if_missing_remote_file("srcdir/kmod-lustre-client-2.10.5.x86_64.rpm")
        .with(source: "https://downloads.whamcloud.com/public/lustre/lustre-2.10.5/el7.5.1804/client/RPMS/x86_64/kmod-lustre-client-2.10.5-1.el7.x86_64.rpm")
        .with(mode: '0644')
        .with(retries: 3)
        .with(retry_delay: 5)

      is_expected.to install_package('lustre_kmod')
        .with(source: "srcdir/kmod-lustre-client-2.10.5.x86_64.rpm")
    end

    it 'installs lustre-client from downloaded rpm' do
      is_expected.to create_if_missing_remote_file("srcdir/lustre-client-2.10.5.x86_64.rpm")
        .with(source: "https://downloads.whamcloud.com/public/lustre/lustre-2.10.5/el7.5.1804/client/RPMS/x86_64/lustre-client-2.10.5-1.el7.x86_64.rpm")
        .with(mode: '0644')
        .with(retries: 3)
        .with(retry_delay: 5)

      is_expected.to install_package('lustre_client')
        .with(source: "srcdir/lustre-client-2.10.5.x86_64.rpm")
    end

    it 'installs kernel module lnet' do
      is_expected.to install_kernel_module("lnet")
    end
  end

  context "on centos 7.6" do
    cached(:chef_run) do
      runner = runner(
        platform: 'centos', version: '7',
        step_into: ['lustre']
      ) do |node|
        node.automatic['platform_version'] = "7.6"
        node.override['cluster']['sources_dir'] = "srcdir"
      end
      Lustre.setup(runner)
    end

    it 'installs kmod-lustre-client from downloaded rpm' do
      is_expected.to create_if_missing_remote_file("srcdir/kmod-lustre-client-2.10.8.x86_64.rpm")
        .with(source: "https://downloads.whamcloud.com/public/lustre/lustre-2.10.8/el7/client/RPMS/x86_64/kmod-lustre-client-2.10.8-1.el7.x86_64.rpm")
        .with(mode: '0644')
        .with(retries: 3)
        .with(retry_delay: 5)

      is_expected.to install_package('lustre_kmod')
        .with(source: "srcdir/kmod-lustre-client-2.10.8.x86_64.rpm")
    end

    it 'installs lustre-client from downloaded rpm' do
      is_expected.to create_if_missing_remote_file("srcdir/lustre-client-2.10.8.x86_64.rpm")
        .with(source: "https://downloads.whamcloud.com/public/lustre/lustre-2.10.8/el7/client/RPMS/x86_64/lustre-client-2.10.8-1.el7.x86_64.rpm")
        .with(mode: '0644')
        .with(retries: 3)
        .with(retry_delay: 5)

      is_expected.to install_package('lustre_client')
        .with(source: "srcdir/lustre-client-2.10.8.x86_64.rpm")
    end

    it 'installs kernel module lnet' do
      is_expected.to install_kernel_module("lnet")
    end
  end

  context "on centos 7.7 or higher" do
    cached(:chef_run) do
      runner = runner(
        platform: 'centos', version: '7',
        step_into: ['lustre']
      ) do |node|
        node.automatic['platform_version'] = "7.7"
      end
      Lustre.setup(runner)
    end

    stubs_for_resource('lustre') do |res|
      allow(res).to receive(:find_centos_minor_version).and_return('minor')
    end

    it 'installs lustre packages from repository and installs kernel module lnet' do
      is_expected.to create_yum_repository("aws-fsx")
        .with(baseurl: 'https://fsx-lustre-client-repo.s3.amazonaws.com/el/7.minor/x86_64/')
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

describe 'lustre:find_centos_minor_version' do
  context "centos version is not 7" do
    cached(:chef_run) do
      runner = runner(
        platform: 'centos', version: '7',
        step_into: ['lustre']
      ) do |node|
        node.automatic['platform_version'] = "8"
      end
      Lustre.setup(runner)
    end

    it 'raises error' do
      expect { chef_run }.to(raise_error do |error|
        expect(error).to be_a(Exception)
        # This can not happen because the resource is defined only for Centos7
        # expect(error.message).to include("CentOS version 8 not supported")
        expect(error.message).to include("Cannot find a resource for lustre on centos version 8")
      end)
    end
  end

  context('on centos 7') do
    context "kernel release does not match expected format" do
      cached(:chef_run) do
        runner = runner(
          platform: 'centos', version: '7',
          step_into: ['lustre']
        ) do |node|
          node.automatic['platform_version'] = "7.7"
          node.override['cluster']['kernel_release'] = 'unexpected.format'
        end
        Lustre.setup(runner)
      end

      it 'raises error' do
        expect { chef_run }.to(raise_error do |error|
          expect(error).to be_a(Exception)
          expect(error.message).to include("Unable to retrieve the kernel patch version from unexpected.format.")
        end)
      end
    end

    context "kernel release below 3.10.0-1062" do
      cached(:chef_run) do
        runner = runner(
          platform: 'centos', version: '7',
          step_into: ['lustre']
        ) do |node|
          node.automatic['platform_version'] = "7.7"
          node.override['cluster']['kernel_release'] = '3.10.0-1061.8.2.el7.x86_64'
        end
        Lustre.setup(runner)
      end

      it 'uses empty minor version' do
        is_expected.to create_yum_repository("aws-fsx")
          .with(baseurl: 'https://fsx-lustre-client-repo.s3.amazonaws.com/el/7./x86_64/')
      end
    end

    context "kernel release 3.10.0-1062 to 3.10.0-1126" do
      cached(:chef_run) do
        runner = runner(
          platform: 'centos', version: '7',
          step_into: ['lustre']
        ) do |node|
          node.automatic['platform_version'] = "7.7"
          node.override['cluster']['kernel_release'] = '3.10.0-1062.8.2.el7.x86_64'
        end
        Lustre.setup(runner)
      end

      it 'uses minor version 7' do
        is_expected.to create_yum_repository("aws-fsx")
          .with(baseurl: 'https://fsx-lustre-client-repo.s3.amazonaws.com/el/7.7/x86_64/')
      end
    end

    context "kernel release 3.10.0-1127 to 3.10.0-1167" do
      cached(:chef_run) do
        runner = runner(
          platform: 'centos', version: '7',
          step_into: ['lustre']
        ) do |node|
          node.automatic['platform_version'] = "7.7"
          node.override['cluster']['kernel_release'] = '3.10.0-1127.8.2.el7.x86_64'
        end
        Lustre.setup(runner)
      end

      it 'uses minor version 7' do
        is_expected.to create_yum_repository("aws-fsx")
          .with(baseurl: 'https://fsx-lustre-client-repo.s3.amazonaws.com/el/7.8/x86_64/')
      end
    end

    context "kernel from 3.10.0-1168 on" do
      cached(:chef_run) do
        runner = runner(
          platform: 'centos', version: '7',
          step_into: ['lustre']
        ) do |node|
          node.automatic['platform_version'] = "7.7"
          node.override['cluster']['kernel_release'] = '3.10.0-1168.8.2.el7.x86_64'
        end
        Lustre.setup(runner)
      end

      it 'uses minor version 7' do
        is_expected.to create_yum_repository("aws-fsx")
          .with(baseurl: 'https://fsx-lustre-client-repo.s3.amazonaws.com/el/7.9/x86_64/')
      end
    end
  end
end
