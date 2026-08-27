require 'spec_helper'

class ConvergeEfs
  def self.install_utils(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-environment') do
      efs 'install_utils' do
        action :install_utils
      end
    end
  end
end

def mock_already_installed(installed)
  stubs_for_resource('efs') do |res|
    allow(res).to receive(:already_installed?).and_return(installed)
  end
end

describe 'efs:install_utils' do
  cached(:utils_version) { '9.8.7' }
  cached(:utils_major) { utils_version.split('.').first.to_i }
  cached(:efs_domain) { 'https://amazon-efs-utils.aws.com' }

  # RHEL/Rocky: install the pinned amazon-efs-utils RPM from the EFS yum repo.
  for_oses([
    %w(redhat 8),
    %w(rocky 8),
    %w(redhat 9),
    %w(rocky 9),
  ]) do |platform, version|
    context "on #{platform}#{version}" do
      cached(:repo_base_url) { "#{efs_domain}/repo/rpm/redhat/#{version.to_i}.*" }

      context "utils package not yet installed" do
        cached(:sources_dir) { 'sources_dir' }
        cached(:gpg_key_path) { "#{sources_dir}/efs-utils-armored.gpg" }
        cached(:chef_run) do
          mock_already_installed(false)
          runner = runner(platform: platform, version: version, step_into: ['efs']) do |node|
            node.override['cluster']['efs']['version'] = utils_version
            node.override['cluster']['sources_dir'] = sources_dir
          end
          ConvergeEfs.install_utils(runner)
        end

        it 'imports the efs-utils gpg key before adding the repository' do
          is_expected.to create_remote_file(gpg_key_path)
            .with(source: "#{efs_domain}/efs-utils-armored.gpg")
          is_expected.to run_execute('import efs-utils gpg key')
            .with(command: "rpm --import #{gpg_key_path}")
        end

        it 'adds the efs-utils yum repository' do
          is_expected.to create_yum_repository('efs-utils')
            .with(baseurl: repo_base_url)
            .with(gpgkey: "file://#{gpg_key_path}")
        end

        it 'installs the newest amazon-efs-utils within the tracked major' do
          is_expected.to run_execute('install amazon-efs-utils')
            .with(command: "dnf install -y 'amazon-efs-utils < #{utils_major + 1}'")
            .with(retries: 3)
            .with(retry_delay: 5)
        end
      end

      context "utils package already installed" do
        cached(:chef_run) do
          mock_already_installed(true)
          runner = runner(platform: platform, version: version, step_into: ['efs']) do |node|
            node.override['cluster']['efs']['version'] = utils_version
          end
          ConvergeEfs.install_utils(runner)
        end

        it 'does not add the efs-utils repository' do
          is_expected.not_to create_yum_repository('efs-utils')
        end

        it 'does not install the package' do
          is_expected.not_to run_execute('install amazon-efs-utils')
        end
      end

      # ADC (us-iso): the per-region S3 bucket is a raw package drop, not a served
      # yum repo, so download the RPM and install the local file instead.
      context "in an ADC (us-iso) region" do
        cached(:iso_region) { 'us-iso-test-1' }
        cached(:iso_domain) { 'test.aws.domain' }
        cached(:sources_dir) { '/fake/sources' }
        cached(:rpm_file) { "amazon-efs-utils-#{utils_version}-1.x86_64.rpm" }
        cached(:rpm_url) do
          "https://s3-efs-utils-mvp-prod-#{iso_region}.s3.#{iso_region}.#{iso_domain}/#{rpm_file}"
        end
        cached(:chef_run) do
          mock_already_installed(false)
          allow_any_instance_of(Object).to receive(:aws_region).and_return(iso_region)
          allow_any_instance_of(Object).to receive(:aws_domain).and_return(iso_domain)
          runner = runner(platform: platform, version: version, step_into: ['efs']) do |node|
            node.override['cluster']['efs']['version'] = utils_version
            node.override['cluster']['sources_dir'] = sources_dir
          end
          ConvergeEfs.install_utils(runner)
        end

        it 'does not add a yum repository' do
          is_expected.not_to create_yum_repository('efs-utils')
        end

        it 'downloads the RPM from the EFS per-region S3 bucket' do
          is_expected.to create_if_missing_remote_file("#{sources_dir}/#{rpm_file}")
            .with(source: rpm_url)
        end

        it 'installs the downloaded RPM locally' do
          is_expected.to run_bash('install amazon-efs-utils from S3 rpm')
            .with(code: "yum install -y ./#{rpm_file}")
        end
      end
    end
  end

  # Amazon Linux 2023: amazon-efs-utils ships in the OS repo (no EFS repo added).
  context "on amazon2023" do
    cached(:chef_run) do
      mock_already_installed(false)
      runner = runner(platform: 'amazon', version: '2023', step_into: ['efs']) do |node|
        node.override['cluster']['efs']['version'] = utils_version
      end
      ConvergeEfs.install_utils(runner)
    end

    it 'does not add an EFS repository' do
      is_expected.not_to create_yum_repository('efs-utils')
    end

    it 'installs the newest amazon-efs-utils within the tracked major from the OS repo' do
      is_expected.to run_execute('install amazon-efs-utils')
        .with(command: "dnf install -y 'amazon-efs-utils < #{utils_major + 1}'")
    end
  end

  # Ubuntu: install amazon-efs-utils deb from the EFS apt repo.
  for_oses([
    %w(ubuntu 22.04),
    %w(ubuntu 24.04),
  ]) do |platform, version|
    context "on #{platform}#{version}" do
      context "utils package not yet installed" do
        cached(:chef_run) do
          mock_already_installed(false)
          runner = runner(platform: platform, version: version, step_into: ['efs']) do |node|
            node.override['cluster']['efs']['version'] = utils_version
          end
          ConvergeEfs.install_utils(runner)
        end

        it 'adds the efs-utils apt repository' do
          is_expected.to add_apt_repository('efs-utils')
            .with(uri: "#{efs_domain}/repo/deb/ubuntu/#{version}")
            .with(distribution: version)
            .with(key: ["#{efs_domain}/efs-utils.gpg"])
        end

        it 'installs the newest amazon-efs-utils within the tracked major keeping the existing conf' do
          is_expected.to run_execute('install amazon-efs-utils')
            .with(command: "apt-get install -y -o Dpkg::Options::=\"--force-confold\" -o Dpkg::Options::=\"--force-confdef\" 'amazon-efs-utils=#{utils_major}.*'")
        end
      end

      context "utils package already installed" do
        cached(:chef_run) do
          mock_already_installed(true)
          runner = runner(platform: platform, version: version, step_into: ['efs']) do |node|
            node.override['cluster']['efs']['version'] = utils_version
          end
          ConvergeEfs.install_utils(runner)
        end

        it 'does not add the efs-utils repository' do
          is_expected.not_to add_apt_repository('efs-utils')
        end

        it 'does not install the package' do
          is_expected.not_to run_execute('install amazon-efs-utils')
        end
      end
    end
  end

  # DevSetting efs.skip_install so the recipe must install nothing regardless of
  # OS/repo flavor. It arrives as the string "true"/"false" via ExtraChefAttributes.
  for_all_oses do |platform, version|
    [true, 'true'].each do |skip_value|
      context "with efs.skip_install #{skip_value.inspect} on #{platform}#{version}" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version, step_into: ['efs']) do |node|
            node.override['cluster']['efs']['version'] = utils_version
            node.override['cluster']['efs']['skip_install'] = skip_value
          end
          ConvergeEfs.install_utils(runner)
        end

        it 'does not add any efs-utils repository' do
          is_expected.not_to create_yum_repository('efs-utils')
          is_expected.not_to add_apt_repository('efs-utils')
        end

        it 'does not install amazon-efs-utils' do
          is_expected.not_to run_execute('install amazon-efs-utils')
        end
      end
    end

    # The string "false" is truthy in Ruby, so it must NOT skip the install.
    context "with efs.skip_install \"false\" on #{platform}#{version}" do
      cached(:chef_run) do
        mock_already_installed(false)
        runner = runner(platform: platform, version: version, step_into: ['efs']) do |node|
          node.override['cluster']['efs']['version'] = utils_version
          node.override['cluster']['efs']['skip_install'] = 'false'
        end
        ConvergeEfs.install_utils(runner)
      end

      it 'still installs amazon-efs-utils' do
        is_expected.to run_execute('install amazon-efs-utils')
      end
    end
  end
end

describe 'efs:mount' do
  for_all_oses do |platform, version|
    %w(HeadNode ComputeFleet).each do |node_type|
      context "on #{platform}#{version} and node type #{node_type}" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version, step_into: ['efs']) do |node|
            node.override['cluster']['region'] = "REGION"
            node.override['cluster']['aws_domain'] = "DOMAIN"
            node.override['cluster']['node_type'] = node_type
          end
          runner.converge_dsl do
            efs 'mount' do
              efs_fs_id_array %w(id_1 id_2 id_3 id_4)
              shared_dir_array %w(shared_dir_1 /shared_dir_2 /shared_dir_3 /shared_dir_4)
              efs_encryption_in_transit_array %w(true true not_true true)
              efs_iam_authorization_array %w(not_true true true true)
              efs_access_point_id_array %w(none none none ap)
              action :mount
            end
          end
        end

        before do
          stub_command("mount | grep ' /shared_dir_1 '").and_return(false)
          stub_command("mount | grep ' /shared_dir_2 '").and_return(true)
          stub_command("mount | grep ' /shared_dir_3 '").and_return(true)
          stub_command("mount | grep ' /shared_dir_4 '").and_return(false)
        end

        it 'mounts efs' do
          is_expected.to mount_efs('mount')
        end

        it 'creates shared directory' do
          %w(/shared_dir_1 /shared_dir_2 /shared_dir_3 /shared_dir_4).each do |shared_dir|
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

          is_expected.to mount_mount('/shared_dir_4')
            .with(device: 'id_4:/')
            .with(fstype: 'efs')
            .with(dump: 0)
            .with(pass: 0)
            .with(options: %w(_netdev noresvport tls iam accesspoint=ap))
            .with(retries: 10)
            .with(retry_delay: 60)
        end

        it 'enables shared dir mount if already mounted' do
          is_expected.to enable_mount('/shared_dir_2')
            .with(device: 'id_2:/')
            .with(fstype: 'efs')
            .with(dump: 0)
            .with(pass: 0)
            .with(options: %w(_netdev noresvport tls iam))
            .with(retries: 10)
            .with(retry_delay: 6)

          is_expected.to enable_mount('/shared_dir_3')
            .with(device: 'id_3:/')
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
        runner = runner(platform: platform, version: version, step_into: ['efs']) do |node|
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

      it 'unmounts efs' do
        is_expected.to unmount_efs('unmount')
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

describe 'efs:already_installed?' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner(platform: platform, version: version, step_into: ['efs']).converge_dsl('aws-parallelcluster-environment') do
          efs 'query' do
            action :nothing
          end
        end
      end
      cached(:resource) { chef_run.find_resource('efs', 'query') }

      it 'reports installed when mount.efs is found, regardless of version' do
        allow(::File).to receive(:exist?).and_call_original
        allow(::File).to receive(:exist?).with('/usr/sbin/mount.efs').and_return(true)
        expect(resource.already_installed?).to be true
      end

      it 'reports not installed when mount.efs is absent' do
        allow(::File).to receive(:exist?).and_call_original
        allow(::File).to receive(:exist?).with('/usr/sbin/mount.efs').and_return(false)
        expect(resource.already_installed?).to be false
      end
    end
  end
end
