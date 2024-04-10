require 'spec_helper'

class ConvergeEfs
  def self.install_utils(chef_run)
    chef_run.converge_dsl do
      efs 'install_utils' do
        action :install_utils
      end
    end
  end
end

def mock_get_package_version(package, expected_version)
  stubs_for_resource('efs') do |res|
    allow(res).to receive(:get_package_version).with(package).and_return(expected_version)
  end
end

def mock_already_installed(package, expected_version, installed)
  stubs_for_resource('efs') do |res|
    allow(res).to receive(:already_installed?).with(package, expected_version).and_return(installed)
  end
end

describe 'efs:install_utils' do
  context "on amazon2" do
    let(:chef_run) do
      ChefSpec::Runner.new(
        platform: 'amazon', version: '2',
        step_into: ['efs']
      ) do |node|
        node.override['cluster']['efs_utils']['version'] = '1.2.3'
      end
    end

    context "when same version of amazon-efs-utils already installed" do
      before do
        mock_get_package_version('amazon-efs-utils', '1.2.3')
        ConvergeEfs.install_utils(chef_run)
      end

      it 'does not install amazon-efs-utils' do
        is_expected.not_to install_package('amazon-efs-utils')
      end
    end

    context "when newer version of amazon-efs-utils already installed" do
      before do
        mock_get_package_version('amazon-efs-utils', '1.3.2')
        ConvergeEfs.install_utils(chef_run)
      end

      it 'does not install amazon-efs-utils' do
        is_expected.not_to install_package('amazon-efs-utils')
      end
    end

    context "when amazon-efs-utils not installed" do
      before do
        mock_get_package_version('amazon-efs-utils', '')
        ConvergeEfs.install_utils(chef_run)
      end

      it 'installs amazon-efs-utils' do
        is_expected.to install_package('amazon-efs-utils').with(retries: 3).with(retry_delay: 5)
      end
    end

    context "when older version of amazon-efs-utils installed" do
      before do
        mock_get_package_version('amazon-efs-utils', '1.1.4')
        ConvergeEfs.install_utils(chef_run)
      end

      it 'installs amazon-efs-utils' do
        is_expected.to install_package('amazon-efs-utils').with(retries: 3).with(retry_delay: 5)
      end
    end
  end

  for_oses([
             %w(ubuntu 18.04),
             %w(ubuntu 20.04),
           ]) do |platform, version|
    context "on #{platform}#{version}" do
      cached(:tarball_path) { 'TARBALL PATH' }
      cached(:tarball_url) { 'https://TARBALL/URL' }
      cached(:tarball_checksum) { 'TARBALL CHECKSUM' }
      cached(:source_dir) { 'SOURCE DIR' }
      cached(:utils_version) { '1.2.3' }
      cached(:bash_code) do
        <<-EFSUTILSINSTALL
      set -e
      tar xf #{tarball_path}
      cd efs-utils-#{utils_version}
      ./build-deb.sh
      apt-get -y install ./build/amazon-efs-utils*deb
      EFSUTILSINSTALL
      end

      context "utils package not yet installed" do
        cached(:chef_run) do
          mock_already_installed('amazon-efs-utils', utils_version, false)
          runner = ChefSpec::Runner.new(
            platform: platform, version: version,
            step_into: ['efs']
          ) do |node|
            node.override['cluster']['efs_utils']['tarball_path'] = tarball_path
            node.override['cluster']['efs_utils']['url'] = tarball_url
            node.override['cluster']['efs_utils']['sha256'] = tarball_checksum
            node.override['cluster']['efs_utils']['version'] = utils_version
            node.override['cluster']['sources_dir'] = source_dir
          end
          ConvergeEfs.install_utils(runner)
        end
        cached(:node) { chef_run.node }

        it 'downloads tarball' do
          is_expected.to create_if_missing_remote_file(tarball_path)
            .with(source: tarball_url)
            .with(mode: '0644')
            .with(retries: 3)
            .with(retry_delay: 5)
            .with(checksum: tarball_checksum)
        end

        it 'installs package from downloaded tarball' do
          is_expected.to run_bash('install efs utils')
            .with(cwd: source_dir)
            .with(code: bash_code)
        end
      end

      context "utils package already installed" do
        cached(:chef_run) do
          mock_already_installed('amazon-efs-utils', utils_version, true)
          runner = ChefSpec::Runner.new(
            platform: platform, version: version,
            step_into: ['efs']
          ) do |node|
            node.override['cluster']['efs_utils']['tarball_path'] = tarball_path
            node.override['cluster']['efs_utils']['url'] = tarball_url
            node.override['cluster']['efs_utils']['sha256'] = tarball_checksum
            node.override['cluster']['efs_utils']['version'] = utils_version
            node.override['cluster']['sources_dir'] = source_dir
          end
          ConvergeEfs.install_utils(runner)
        end
        cached(:node) { chef_run.node }

        it 'does not download tarball' do
          is_expected.not_to create_if_missing_remote_file(tarball_path)
        end

        it 'does not install package from downloaded tarball' do
          is_expected.not_to run_bash('install efs utils')
        end
      end
    end
  end

  for_oses([
    %w(centos 7),
    %w(redhat 8),
  ]) do |platform, version|
    context "on #{platform}#{version}" do
      cached(:tarball_path) { 'TARBALL PATH' }
      cached(:tarball_url) { 'https://TARBALL/URL' }
      cached(:tarball_checksum) { 'TARBALL CHECKSUM' }
      cached(:source_dir) { 'SOURCE DIR' }
      cached(:utils_version) { '1.2.3' }
      cached(:bash_code) do
        <<-EFSUTILSINSTALL
      set -e
      tar xf #{tarball_path}
      cd efs-utils-#{utils_version}
      make rpm
      yum -y install ./build/amazon-efs-utils*rpm
        EFSUTILSINSTALL
      end
      cached(:required_packages) do
        {
          "centos" => 'rpm-build',
          "redhat" => %w(rpm-build make),
        }
      end

      context "utils package not yet installed" do
        cached(:chef_run) do
          mock_already_installed('amazon-efs-utils', utils_version, false)
          runner = ChefSpec::Runner.new(
            platform: platform, version: version,
            step_into: ['efs']
          ) do |node|
            node.override['cluster']['efs_utils']['tarball_path'] = tarball_path
            node.override['cluster']['efs_utils']['url'] = tarball_url
            node.override['cluster']['efs_utils']['sha256'] = tarball_checksum
            node.override['cluster']['efs_utils']['version'] = utils_version
            node.override['cluster']['sources_dir'] = source_dir
          end
          ConvergeEfs.install_utils(runner)
        end

        it 'installs prerequisites' do
          is_expected.to install_package(required_packages[platform])
            .with(retries: 3)
            .with(retry_delay: 5)
        end

        it 'downloads tarball' do
          is_expected.to create_if_missing_remote_file(tarball_path)
            .with(source: tarball_url)
            .with(mode: '0644')
            .with(retries: 3)
            .with(retry_delay: 5)
            .with(checksum: tarball_checksum)
        end

        it 'installs package from downloaded tarball' do
          is_expected.to run_bash('install efs utils')
            .with(cwd: source_dir)
            .with(code: bash_code)
        end
      end

      context "utils package already installed" do
        cached(:chef_run) do
          mock_already_installed('amazon-efs-utils', utils_version, true)
          runner = ChefSpec::Runner.new(
            platform: platform, version: version,
            step_into: ['efs']
          ) do |node|
            node.override['cluster']['efs_utils']['tarball_path'] = tarball_path
            node.override['cluster']['efs_utils']['url'] = tarball_url
            node.override['cluster']['efs_utils']['sha256'] = tarball_checksum
            node.override['cluster']['efs_utils']['version'] = utils_version
            node.override['cluster']['sources_dir'] = source_dir
          end
          ConvergeEfs.install_utils(runner)
        end

        it 'does not download tarball' do
          is_expected.not_to create_if_missing_remote_file(tarball_path)
        end

        it 'does not install package from downloaded tarball' do
          is_expected.not_to run_bash('install efs utils')
        end
      end
    end
  end
end

describe 'efs:mount' do
  for_all_oses do |platform, version|
    %w(HeadNode ComputeFleet).each do |node_type|
      context "on #{platform}#{version} and node type #{node_type}" do
        cached(:chef_run) do
          runner = ChefSpec::Runner.new(
            platform: platform, version: version,
            step_into: ['efs']
          ) do |node|
            node.override['cluster']['region'] = "REGION"
            node.override['cluster']['aws_domain'] = "DOMAIN"
            node.override['cluster']['node_type'] = node_type
          end
          runner.converge_dsl do
            efs 'mount' do
              efs_fs_id_array %w(id_1 id_2 id_3)
              shared_dir_array %w(shared_dir_1 /shared_dir_2 /shared_dir_3)
              efs_encryption_in_transit_array %w(true true not_true)
              efs_iam_authorization_array %w(not_true true true)
              action :mount
            end
          end
        end

        before do
          stub_command("mount | grep ' /shared_dir_1 '").and_return(false)
          stub_command("mount | grep ' /shared_dir_2 '").and_return(true)
          stub_command("mount | grep ' /shared_dir_3 '").and_return(true)
        end

        it 'creates shared directory' do
          %w(/shared_dir_1 /shared_dir_2 /shared_dir_3).each do |shared_dir|
            is_expected.to create_directory(shared_dir)
              .with(owner: 'root')
              .with(group: 'root')
              .with(mode: '1777')
            # .with(recursive: true) # even if we set recursive a true, the test fails
          end
        end

        it 'mounts shared dir if not already mounted' do
          is_expected.to mount_mount('/shared_dir_1')
            .with(device: 'id_1:/')
            .with(fstype: 'efs')
            .with(dump: 0)
            .with(pass: 0)
            .with(options: %w(_netdev noresvport tls))
            .with(retries: 10)
            .with(retry_delay: 60)
        end

        it 'enables shared dir mount if already mounted' do
          is_expected.to enable_mount('/shared_dir_2')
            .with(device: 'id_2.efs.REGION.DOMAIN:/')
            .with(fstype: 'efs')
            .with(dump: 0)
            .with(pass: 0)
            .with(options: %w(_netdev noresvport tls iam))
            .with(retries: 10)
            .with(retry_delay: 6)

          is_expected.to enable_mount('/shared_dir_3')
            .with(device: 'id_3.efs.REGION.DOMAIN:/')
            .with(fstype: 'efs')
            .with(dump: 0)
            .with(pass: 0)
            .with(options: %w(_netdev noresvport))
            .with(retries: 10)
            .with(retry_delay: 6)
        end

        if node_type == "HeadNode"
          it 'changes permissions' do
            %w(/shared_dir_1 /shared_dir_2 /shared_dir_3).each do |shared_dir|
              is_expected.to create_directory("change permissions for #{shared_dir}")
                .with(path: shared_dir)
                .with(owner: 'root')
                .with(group: 'root')
                .with(mode: '1777')
            end
          end
        end
      end
    end
  end
end

describe 'efs:unmount' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = ChefSpec::Runner.new(
          platform: platform, version: version,
          step_into: ['efs']
        ) do |node|
          node.override['cluster']['region'] = "REGION"
          node.override['cluster']['aws_domain'] = "DOMAIN"
        end
        runner.converge_dsl do
          efs 'unmount' do
            efs_fs_id_array %w(id_1 id_2)
            shared_dir_array %w(shared_dir_1 /shared_dir_2)
            action :unmount
          end
        end
      end

      before do
        stub_command("mount | grep ' /shared_dir_1 '").and_return(false)
        stub_command("mount | grep ' /shared_dir_2 '").and_return(true)
        allow(Dir).to receive(:exist?).with("/shared_dir_1").and_return(true)
        allow(Dir).to receive(:empty?).with("/shared_dir_1").and_return(true)
        allow(Dir).to receive(:exist?).with("/shared_dir_2").and_return(true)
        allow(Dir).to receive(:empty?).with("/shared_dir_2").and_return(false)
      end

      it 'unmounts efs only if mounted' do
        is_expected.not_to run_execute('unmount efs')
          .with(command: 'umount -fl /shared_dir_1')

        is_expected.to run_execute('unmount efs')
          .with(command: "umount -fl /shared_dir_2")
          .with(retries: 10)
          .with(retry_delay: 6)
          .with(timeout: 60)
      end

      %w(/shared_dir_1 /shared_dir_2).each do |shared_dir|
        it "removes volume #{shared_dir} from /etc/fstab" do
          is_expected.to edit_delete_lines("remove volume #{shared_dir} from /etc/fstab")
            .with(path: "/etc/fstab")
            .with(pattern: " #{shared_dir} ")
        end
      end

      it "deletes shared dir only if it exists and it is empty" do
        is_expected.to delete_directory('/shared_dir_1')
          .with(recursive: false)

        is_expected.not_to delete_directory('/shared_dir_2')
      end
    end
  end
end
