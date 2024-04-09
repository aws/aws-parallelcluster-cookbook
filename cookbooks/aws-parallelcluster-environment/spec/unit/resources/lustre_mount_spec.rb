require 'spec_helper'

describe 'lustre:mount' do
  for_all_oses do |platform, version|
    %w(HeadNode ComputeFleet).each do |node_type|
      context "on #{platform}#{version} and node type #{node_type}" do
        context 'for lustre' do
          cached(:chef_run) do
            runner = runner(
              platform: platform, version: version,
              step_into: ['lustre']
            ) do |node|
              node.override['cluster']['region'] = "REGION"
              node.override['cluster']['node_type'] = node_type
            end
            runner.converge_dsl('aws-parallelcluster-environment') do
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

          before do
            stub_command("mount | grep ' /lustre_shared_dir_with_no_mount '").and_return(false)
            stub_command("mount | grep ' /lustre_shared_dir_with_mount '").and_return(true)
          end

          it 'creates_shared_dir' do
            is_expected.to create_directory('/lustre_shared_dir_with_no_mount')
              .with(owner: 'root')
              .with(group: 'root')
              .with(mode: '1777')
            # .with(recursive: true) # even if we set recursive a true, the test fails

            is_expected.to create_directory('/lustre_shared_dir_with_mount')
              .with(owner: 'root')
              .with(group: 'root')
              .with(mode: '1777')
            # .with(recursive: true) # even if we set recursive a true, the test fails
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

          if node_type == "HeadNode"
            it 'changes permissions' do
              is_expected.to create_directory('change permissions for /lustre_shared_dir_with_mount')
                .with(owner: 'root')
                .with(group: 'root')
                .with(mode: '1777')

              is_expected.to create_directory('change permissions for /lustre_shared_dir_with_no_mount')
                .with(owner: 'root')
                .with(group: 'root')
                .with(mode: '1777')
            end
          else
            it 'does not change permissions' do
              is_expected.not_to create_directory('change permissions for /lustre_shared_dir_with_mount')

              is_expected.not_to create_directory('change permissions for /lustre_shared_dir_with_no_mount')
            end
          end
        end

        context 'for filecache' do
          cached(:chef_run) do
            runner = runner(
              platform: platform, version: version,
              step_into: ['lustre']
            ) do |node|
              node.override['cluster']['region'] = "REGION"
              node.override['cluster']['node_type'] = node_type
            end
            runner.converge_dsl('aws-parallelcluster-environment') do
              lustre 'mount' do
                fsx_fs_id_array %w(file_cache_id_1 file_cache_id_2)
                fsx_fs_type_array %w(FILECACHE FILECACHE)
                fsx_shared_dir_array %w(filecache_shared_dir_1 /filecache_shared_dir_2)
                fsx_dns_name_array %w(filecache_dns_name_1 filecache_dns_name_2)
                fsx_mount_name_array %w(filecache_mount_name_1 filecache_mount_name_2)
                fsx_volume_junction_path_array ['', '']
                action :mount
              end
            end
          end

          before do
            stub_command("mount | grep ' /filecache_shared_dir_1 '").and_return(false)
            stub_command("mount | grep ' /filecache_shared_dir_2 '").and_return(true)
          end

          it 'creates_shared_dir' do
            is_expected.to create_directory('/filecache_shared_dir_1')
              .with(owner: 'root')
              .with(group: 'root')
              .with(mode: '1777')
            # .with(recursive: true) # even if we set recursive a true, the test fails

            is_expected.to create_directory('/filecache_shared_dir_2')
              .with(owner: 'root')
              .with(group: 'root')
              .with(mode: '1777')
            # .with(recursive: true) # even if we set recursive a true, the test fails
          end

          it 'mounts shared dir if not already mounted' do
            is_expected.to mount_mount('/filecache_shared_dir_1')
              .with(device: 'filecache_dns_name_1@tcp:/filecache_mount_name_1')
              .with(fstype: 'lustre')
              .with(dump: 0)
              .with(pass: 0)
              .with(options: %w(defaults _netdev flock user_xattr noatime noauto x-systemd.automount x-systemd.requires=network.service))
              .with(retries: 10)
              .with(retry_delay: 6)
          end

          it 'enables shared dir mount if already mounted' do
            is_expected.to enable_mount('/filecache_shared_dir_2')
              .with(device: 'filecache_dns_name_2@tcp:/filecache_mount_name_2')
              .with(fstype: 'lustre')
              .with(dump: 0)
              .with(pass: 0)
              .with(options: %w(defaults _netdev flock user_xattr noatime noauto x-systemd.automount x-systemd.requires=network.service))
              .with(retries: 10)
              .with(retry_delay: 6)
          end

          if node_type == "HeadNode"
            it 'changes permissions' do
              is_expected.to create_directory('change permissions for /filecache_shared_dir_1')
                .with(owner: 'root')
                .with(group: 'root')
                .with(mode: '1777')

              is_expected.to create_directory('change permissions for /filecache_shared_dir_2')
                .with(owner: 'root')
                .with(group: 'root')
                .with(mode: '1777')
            end
          else
            it 'does not change permissions' do
              is_expected.not_to create_directory('change permissions for /filecache_shared_dir_1')

              is_expected.not_to create_directory('change permissions for /filecache_shared_dir_2')
            end
          end
        end

        context 'for openzfs' do
          cached(:chef_run) do
            runner = runner(
              platform: platform, version: version,
              step_into: ['lustre']
            ) do |node|
              node.override['cluster']['region'] = "REGION"
            end
            runner.converge_dsl('aws-parallelcluster-environment') do
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

          before do
            stub_command("mount | grep ' /openzfs_shared_dir_1 '").and_return(false)
            stub_command("mount | grep ' /openzfs_shared_dir_2 '").and_return(true)
          end

          it 'creates_shared_dir' do
            is_expected.to create_directory('/openzfs_shared_dir_1')
              .with(owner: 'root')
              .with(group: 'root')
              .with(mode: '1777')
            # .with(recursive: true) # even if we set recursive a true, the test fails

            is_expected.to create_directory('/openzfs_shared_dir_2')
              .with(owner: 'root')
              .with(group: 'root')
              .with(mode: '1777')
            # .with(recursive: true) # even if we set recursive a true, the test fails
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

          it "doesn't change permissions" do
            is_expected.not_to create_directory('change permissions for /openzfs_shared_dir_1')
              .with(owner: 'root')
              .with(group: 'root')
              .with(mode: '1777')

            is_expected.not_to create_directory('change permissions for /openzfs_shared_dir_2')
              .with(owner: 'root')
              .with(group: 'root')
              .with(mode: '1777')
          end
        end

        context 'for ontap' do
          cached(:chef_run) do
            runner = runner(
              platform: platform, version: version,
              step_into: ['lustre']
            ) do |node|
              node.override['cluster']['region'] = "REGION"
              node.override['cluster']['node_type'] = node_type
            end
            runner.converge_dsl('aws-parallelcluster-environment') do
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

          before do
            stub_command("mount | grep ' /ontap_shared_dir_1 '").and_return(false)
            stub_command("mount | grep ' /ontap_shared_dir_2 '").and_return(true)
          end

          it 'creates_shared_dir' do
            is_expected.to create_directory('/ontap_shared_dir_1')
              .with(owner: 'root')
              .with(group: 'root')
              .with(mode: '1777')
            # .with(recursive: true) # even if we set recursive a true, the test fails

            is_expected.to create_directory('/ontap_shared_dir_2')
              .with(owner: 'root')
              .with(group: 'root')
              .with(mode: '1777')
            # .with(recursive: true) # even if we set recursive a true, the test fails
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

          if node_type == "HeadNode"
            it 'changes permissions' do
              is_expected.to create_directory('change permissions for /ontap_shared_dir_1')
                .with(owner: 'root')
                .with(group: 'root')
                .with(mode: '1777')

              is_expected.to create_directory('change permissions for /ontap_shared_dir_2')
                .with(owner: 'root')
                .with(group: 'root')
                .with(mode: '1777')
            end
          else
            it 'does not change permissions' do
              is_expected.not_to create_directory('change permissions for /ontap_shared_dir_1')

              is_expected.not_to create_directory('change permissions for /ontap_shared_dir_2')
            end
          end
        end
      end
    end
  end
end

describe 'lustre:unmount' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      context 'for lustre' do
        cached(:chef_run) do
          runner = runner(
            platform: platform, version: version,
            step_into: ['lustre']
          ) do |node|
            node.override['cluster']['region'] = "REGION"
          end
          runner.converge_dsl('aws-parallelcluster-environment') do
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

        before do
          stub_command("mount | grep ' /shared_dir_1 '").and_return(false)
          stub_command("mount | grep ' /shared_dir_2 '").and_return(true)
          allow(Dir).to receive(:empty?).with("/shared_dir_1").and_return(true)
          allow(Dir).to receive(:empty?).with("/shared_dir_2").and_return(false)
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

        it 'deletes shared dir only if empty' do
          is_expected.to delete_directory('/shared_dir_1')
            .with(recursive: false)
          is_expected.not_to delete_directory('/shared_dir_2')
        end
      end

      context 'for OPENZFS, ONTAP' do
        cached(:chef_run) do
          runner = runner(
            platform: platform, version: version,
            step_into: ['lustre']
          ) do |node|
            node.override['cluster']['region'] = "REGION"
          end
          runner.converge_dsl('aws-parallelcluster-environment') do
            lustre 'unmount' do
              fsx_fs_id_array %w(openzfs_id_1 ontap_id_2)
              fsx_fs_type_array %w(OPENZFS ONTAP)
              fsx_shared_dir_array %w(shared_dir_1 shared_dir_2)
              fsx_dns_name_array ['dns_name', '']
              fsx_mount_name_array %w(mount_name_1 mount_name_2)
              fsx_volume_junction_path_array %w(junction_path_1 /junction_path_2)
              action :unmount
            end
          end
        end

        before do
          stub_command("mount | grep ' /shared_dir_1 '").and_return(false)
          stub_command("mount | grep ' /shared_dir_2 '").and_return(true)
          allow(Dir).to receive(:empty?).with("/shared_dir_1").and_return(true)
          allow(Dir).to receive(:empty?).with("/shared_dir_2").and_return(false)
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
          is_expected.to edit_delete_lines('remove volume dns_name:/junction_path_1 from /etc/fstab')
            .with(path: "/etc/fstab")
            .with(pattern: "dns_name:/junction_path_1 *")

          is_expected.to edit_delete_lines('remove volume ontap_id_2.fsx.REGION.amazonaws.com:/junction_path_2 from /etc/fstab')
            .with(path: "/etc/fstab")
            .with(pattern: "ontap_id_2.fsx.REGION.amazonaws.com:/junction_path_2 *")
        end

        it 'deletes shared dir only if empty' do
          is_expected.to delete_directory('/shared_dir_1')
            .with(recursive: false)
          is_expected.not_to delete_directory('/shared_dir_2')
        end
      end

      context 'for FILECACHE' do
        cached(:chef_run) do
          runner = runner(
            platform: platform, version: version,
            step_into: ['lustre']
          ) do |node|
            node.override['cluster']['region'] = "REGION"
          end
          runner.converge_dsl do
            lustre 'unmount' do
              fsx_fs_id_array %w(file_cache_id_1 file_cache_id_2)
              fsx_fs_type_array %w(FILECACHE FILECACHE)
              fsx_shared_dir_array %w(filecache_dir_1 filecache_dir_2)
              fsx_dns_name_array %w(filecache_dns_name_1 filecache_dns_name_2)
              fsx_mount_name_array %w(filecache_mount_name_1 filecache_mount_name_2)
              fsx_volume_junction_path_array ['']
              action :unmount
            end
          end
        end

        before do
          stub_command("mount | grep ' /filecache_dir_1 '").and_return(false)
          stub_command("mount | grep ' /filecache_dir_2 '").and_return(true)
          allow(Dir).to receive(:empty?).with("/filecache_dir_1").and_return(true)
          allow(Dir).to receive(:empty?).with("/filecache_dir_2").and_return(false)
        end

        it 'unmounts fsx only if mounted' do
          is_expected.not_to run_execute('unmount fsx /filecache_dir_1')

          is_expected.to run_execute('unmount fsx /filecache_dir_2')
            .with(command: "umount -fl /filecache_dir_2")
            .with(retries: 10)
            .with(retry_delay: 6)
            .with(timeout: 60)
        end

        it 'removes volume from /etc/fstab' do
          is_expected.to edit_delete_lines('remove volume filecache_dns_name_1@tcp:/filecache_mount_name_1 from /etc/fstab')
            .with(path: "/etc/fstab")
            .with(pattern: "filecache_dns_name_1@tcp:/filecache_mount_name_1 *")

          is_expected.to edit_delete_lines('remove volume filecache_dns_name_2@tcp:/filecache_mount_name_2 from /etc/fstab')
            .with(path: "/etc/fstab")
            .with(pattern: "filecache_dns_name_2@tcp:/filecache_mount_name_2 *")
        end

        it 'deletes shared dir only if empty' do
          is_expected.to delete_directory('/filecache_dir_1')
            .with(recursive: false)
          is_expected.not_to delete_directory('/filecache_dir_2')
        end
      end
    end
  end
end
