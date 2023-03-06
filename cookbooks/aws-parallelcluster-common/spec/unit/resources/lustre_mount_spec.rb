require 'spec_helper'

class Lustre
  def self.mount(chef_run)
    chef_run.converge_dsl do
      lustre 'mount' do
        action :mount
      end
    end
  end
end

describe 'lustre:mount' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      context 'for lustre' do
        let(:chef_run) do
          ChefSpec::Runner.new(
            platform: platform, version: version,
            step_into: ['lustre']
          ) do |node|
            node.override['cluster']['region'] = "REGION"
          end
        end

        before do
          stub_command("mount | grep ' /lustre_shared_dir_with_no_mount '").and_return(false)
          stub_command("mount | grep ' /lustre_shared_dir_with_mount '").and_return(true)
          chef_run.converge_dsl do
            lustre 'mount' do
              fsx_fs_id_array %w(lustre_id_1 lustre_id_2)
              fsx_fs_type_array %w(LUSTRE LUSTRE)
              fsx_shared_dir_array %w(lustre_shared_dir_with_no_mount lustre_shared_dir_with_mount)
              fsx_dns_name_array ['lustre_dns_name', '']
              fsx_mount_name_array %w(lustre_mount_name_1 lustre_mount_name_2)
              fsx_volume_junction_path_array ['', '']
              action :mount
            end
          end
        end

        it 'creates_shared_dir' do
          is_expected.to create_directory('/lustre_shared_dir_with_no_mount')
            .with(owner: 'root')
            .with(group: 'root')
            .with(mode: '1777')
          # .with(recursive: false)

          is_expected.to create_directory('/lustre_shared_dir_with_mount')
            .with(owner: 'root')
            .with(group: 'root')
            .with(mode: '1777')
          # .with(recursive: true)
        end

        it 'mounts shared dir if not already mounted' do
          is_expected.to mount_mount('/lustre_shared_dir_with_no_mount')
            .with(device: 'lustre_dns_name@tcp:/lustre_mount_name_1')
            .with(fstype: 'lustre')
            .with(dump: 0)
            .with(pass: 0)
            .with(options: %w(defaults _netdev flock user_xattr noatime noauto x-systemd.automount))
            .with(retries: 10)
            .with(retry_delay: 6)
        end

        it 'enables shared dir mount if already mounted' do
          is_expected.to enable_mount('/lustre_shared_dir_with_mount')
            .with(device: 'lustre_id_2.fsx.REGION.amazonaws.com@tcp:/lustre_mount_name_2')
            .with(fstype: 'lustre')
            .with(dump: 0)
            .with(pass: 0)
            .with(options: %w(defaults _netdev flock user_xattr noatime noauto x-systemd.automount))
            .with(retries: 10)
            .with(retry_delay: 6)
        end
      end

      context 'for openzfs' do
        let(:chef_run) do
          ChefSpec::Runner.new(
            platform: platform, version: version,
            step_into: ['lustre']
          ) do |node|
            node.override['cluster']['region'] = "REGION"
          end
        end

        before do
          stub_command("mount | grep ' /openzfs_shared_dir_1 '").and_return(false)
          stub_command("mount | grep ' /openzfs_shared_dir_2 '").and_return(true)
          chef_run.converge_dsl do
            lustre 'mount' do
              fsx_fs_id_array %w(openzfs_id_1 openzfs_id_2)
              fsx_fs_type_array %w(OPENZFS OPENZFS)
              fsx_shared_dir_array %w(openzfs_shared_dir_1 /openzfs_shared_dir_2)
              fsx_dns_name_array ['openzfs_dns_name', '']
              fsx_mount_name_array %w(openzfs_mount_name_1 openzfs_mount_name_2)
              fsx_volume_junction_path_array %w(junction_path_1 /junction_path_2)
              action :mount
            end
          end
        end

        it 'creates_shared_dir' do
          is_expected.to create_directory('/openzfs_shared_dir_1')
            .with(owner: 'root')
            .with(group: 'root')
            .with(mode: '1777')
          # .with(recursive: false)

          is_expected.to create_directory('/openzfs_shared_dir_2')
            .with(owner: 'root')
            .with(group: 'root')
            .with(mode: '1777')
          # .with(recursive: true)
        end

        it 'mounts shared dir if not already mounted' do
          is_expected.to mount_mount('/openzfs_shared_dir_1')
            .with(device: 'openzfs_dns_name:/junction_path_1')
            .with(fstype: 'nfs')
            .with(dump: 0)
            .with(pass: 0)
            .with(options: %w(nfsvers=4.2))
            .with(retries: 10)
            .with(retry_delay: 6)
        end

        it 'enables shared dir mount if already mounted' do
          is_expected.to enable_mount('/openzfs_shared_dir_2')
            .with(device: 'openzfs_id_2.fsx.REGION.amazonaws.com:/junction_path_2')
            .with(fstype: 'nfs')
            .with(dump: 0)
            .with(pass: 0)
            .with(options: %w(nfsvers=4.2))
            .with(retries: 10)
            .with(retry_delay: 6)
        end
      end

      context 'for ontap' do
        let(:chef_run) do
          ChefSpec::Runner.new(
            platform: platform, version: version,
            step_into: ['lustre']
          ) do |node|
            node.override['cluster']['region'] = "REGION"
          end
        end

        before do
          stub_command("mount | grep ' /ontap_shared_dir_1 '").and_return(false)
          stub_command("mount | grep ' /ontap_shared_dir_2 '").and_return(true)
          chef_run.converge_dsl do
            lustre 'mount' do
              fsx_fs_id_array %w(ontap_id_1 ontap_id_2)
              fsx_fs_type_array %w(ONTAP ONTAP)
              fsx_shared_dir_array %w(ontap_shared_dir_1 /ontap_shared_dir_2)
              fsx_dns_name_array ['ontap_dns_name', '']
              fsx_mount_name_array %w(ontap_mount_name_1 ontap_mount_name_2)
              fsx_volume_junction_path_array %w(junction_path_1 /junction_path_2)
              action :mount
            end
          end
        end

        it 'creates_shared_dir' do
          is_expected.to create_directory('/ontap_shared_dir_1')
            .with(owner: 'root')
            .with(group: 'root')
            .with(mode: '1777')
          # .with(recursive: false)

          is_expected.to create_directory('/ontap_shared_dir_2')
            .with(owner: 'root')
            .with(group: 'root')
            .with(mode: '1777')
          # .with(recursive: true)
        end

        it 'mounts shared dir if not already mounted' do
          is_expected.to mount_mount('/ontap_shared_dir_1')
            .with(device: 'ontap_dns_name:/junction_path_1')
            .with(fstype: 'nfs')
            .with(dump: 0)
            .with(pass: 0)
            .with(options: %w(defaults))
            .with(retries: 10)
            .with(retry_delay: 6)
        end

        it 'enables shared dir mount if already mounted' do
          is_expected.to enable_mount('/ontap_shared_dir_2')
            .with(device: 'ontap_id_2.fsx.REGION.amazonaws.com:/junction_path_2')
            .with(fstype: 'nfs')
            .with(dump: 0)
            .with(pass: 0)
            .with(options: %w(defaults))
            .with(retries: 10)
            .with(retry_delay: 6)
        end
      end
    end
  end
end

describe 'lustre:unmount' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      context 'for lustre' do
        let(:chef_run) do
          ChefSpec::Runner.new(
            platform: platform, version: version,
            step_into: ['lustre']
          ) do |node|
            node.override['cluster']['region'] = "REGION"
          end
        end

        before do
          stub_command("mount | grep ' /shared_dir_1 '").and_return(false)
          stub_command("mount | grep ' /shared_dir_2 '").and_return(true)
          chef_run.converge_dsl do
            lustre 'unmount' do
              fsx_fs_id_array %w(lustre_id_1 lustre_id_2)
              fsx_fs_type_array %w(LUSTRE LUSTRE)
              fsx_shared_dir_array %w(shared_dir_1 shared_dir_2)
              fsx_dns_name_array ['dns_name', '']
              fsx_mount_name_array %w(mount_name_1 mount_name_2)
              fsx_volume_junction_path_array ['', '']
              action :unmount
            end
          end
        end

        it 'unmounts fsx only if mounted' do
          is_expected.not_to run_execute('unmount fsx /shared_dir_1')

          is_expected.to run_execute('unmount fsx /shared_dir_2')
            .with(command: "umount -fl /shared_dir_2")
            .with(retries: 10)
            .with(retry_delay: 6)
            .with(timeout: 60)
        end

        it 'removes volume from /etc/fstab' do
          is_expected.to edit_delete_lines('remove volume dns_name@tcp:/mount_name_1 from /etc/fstab')
            .with(path: "/etc/fstab")
            .with(pattern: "dns_name@tcp:/mount_name_1 *")

          is_expected.to edit_delete_lines('remove volume lustre_id_2.fsx.REGION.amazonaws.com@tcp:/mount_name_2 from /etc/fstab')
            .with(path: "/etc/fstab")
            .with(pattern: "lustre_id_2.fsx.REGION.amazonaws.com@tcp:/mount_name_2 *")
        end
      end

      context 'for OPENZFS, ONTAP' do
        let(:chef_run) do
          ChefSpec::Runner.new(
            platform: platform, version: version,
            step_into: ['lustre']
          ) do |node|
            node.override['cluster']['region'] = "REGION"
          end
        end

        before do
          stub_command("mount | grep ' /shared_dir_1 '").and_return(false)
          stub_command("mount | grep ' /shared_dir_2 '").and_return(true)
          chef_run.converge_dsl do
            lustre 'unmount' do
              fsx_fs_id_array %w(openzfs_id_1 ontap_id_2)
              fsx_fs_type_array %w(OPENZFS ONTAP)
              fsx_shared_dir_array %w(shared_dir_1 shared_dir_2)
              fsx_dns_name_array ['dns_name', '']
              fsx_mount_name_array %w(mount_name_1 mount_name_2)
              fsx_volume_junction_path_array %w(junction_path_1 junction_path_2)
              action :unmount
            end
          end
        end

        it 'unmounts fsx only if mounted' do
          is_expected.not_to run_execute('unmount fsx /shared_dir_1')

          is_expected.to run_execute('unmount fsx /shared_dir_2')
            .with(command: "umount -fl /shared_dir_2")
            .with(retries: 10)
            .with(retry_delay: 6)
            .with(timeout: 60)
        end

        it 'removes volume from /etc/fstab' do
          is_expected.to edit_delete_lines('remove volume dns_name:junction_path_1 from /etc/fstab')
            .with(path: "/etc/fstab")
            .with(pattern: "dns_name:junction_path_1 *")

          is_expected.to edit_delete_lines('remove volume ontap_id_2.fsx.REGION.amazonaws.com:junction_path_2 from /etc/fstab')
            .with(path: "/etc/fstab")
            .with(pattern: "ontap_id_2.fsx.REGION.amazonaws.com:junction_path_2 *")
        end
      end
    end
  end
end
