require 'spec_helper'

class Chef::Resource::RubyBlock
  def wait_for_block_dev(_path)
    # do nothing
  end
end

describe 'manage_raid:mount' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:venv_path) { 'venv' }
      cached(:raid_superblock_version) do
        platform == 'redhat' || "#{platform}#{version}" == 'ubuntu20.04' ? '1.2' : '0.90'
      end
      cached(:chef_run) do
        runner = ChefSpec::Runner.new(
          platform: platform, version: version,
          step_into: ['manage_raid']
        )
        allow_any_instance_of(Object).to receive(:cookbook_virtualenv_path).and_return(venv_path)
        runner.converge_dsl do
          manage_raid 'mount' do
            action :mount
            raid_vol_array %w(vol-0 vol-1)
            raid_shared_dir "raid_shared_dir"
            raid_type ' 0'
          end
        end
      end

      it "attaches volumes" do
        # Attach RAID EBS volume
        is_expected.to run_execute("attach_raid_volume_0")
          .with(command: "#{venv_path}/bin/python /usr/local/sbin/manageVolume.py --volume-id vol-0 --attach")
          .with(creates: "/dev/disk/by-ebs-volumeid/vol-0")

        is_expected.to run_execute("attach_raid_volume_1")
          .with(command: "#{venv_path}/bin/python /usr/local/sbin/manageVolume.py --volume-id vol-1 --attach")
          .with(creates: "/dev/disk/by-ebs-volumeid/vol-1")

        block = chef_run.find_resource('ruby_block', 'sleeping_for_raid_volume_0')
        expect(block).to receive(:wait_for_block_dev).with('/dev/disk/by-ebs-volumeid/vol-0')
        block.block.call
        expect(block).to subscribe_to('execute[attach_raid_volume_0]').on(:run).immediately

        block = chef_run.find_resource('ruby_block', 'sleeping_for_raid_volume_1')
        expect(block).to receive(:wait_for_block_dev).with('/dev/disk/by-ebs-volumeid/vol-1')
        block.block.call
        expect(block).to subscribe_to('execute[attach_raid_volume_1]').on(:run).immediately
      end

      it "initializes raid" do
        is_expected.to create_mdadm("MY_RAID")
          .with(raid_device: '/dev/md0')
          .with(level: 0)
          .with(metadata: raid_superblock_version)
          .with(devices: %w(/dev/disk/by-ebs-volumeid/vol-0 /dev/disk/by-ebs-volumeid/vol-1))

        block = chef_run.find_resource('ruby_block', 'sleeping_for_raid_block')
        expect(block).to receive(:wait_for_block_dev).with('/dev/md0')
        block.block.call
        expect(block).to subscribe_to('mdadm[MY_RAID]').on(:run).immediately
      end

      it "setups raid disk" do
        is_expected.to nothing_execute("setup_raid_disk")
          .with(command: "sudo mkfs.ext4 /dev/md0")

        command = chef_run.execute("setup_raid_disk")
        expect(command).to subscribe_to('ruby_block[sleeping_for_raid_block]').on(:run).immediately
      end

      it "creates Raid config" do
        is_expected.to nothing_execute("create_raid_config")
          .with(command: "sudo mdadm --detail --scan | sudo tee -a /etc/mdadm.conf")

        command = chef_run.execute("create_raid_config")
        expect(command).to subscribe_to('execute[setup_raid_disk]').on(:run).immediately
      end

      it "creates the shared dir" do
        is_expected.to create_directory('/raid_shared_dir')
          .with(owner: 'root')
          .with(group: 'root')
          .with(mode: '1777')
        # recursive do not work
        # .with(recursive: true)
      end

      it "mounts and enables the shared dir" do
        is_expected.to mount_mount('/raid_shared_dir')
          .with(device: "/dev/md0")
          .with(fstype: "ext4")
          .with(options: %w(defaults nofail _netdev))
          .with(retries: 10)
          .with(retry_delay: 6)

        is_expected.to enable_mount('/raid_shared_dir')
          .with(device: "/dev/md0")
          .with(fstype: "ext4")
          .with(options: %w(defaults nofail _netdev))
          .with(retries: 10)
          .with(retry_delay: 6)
      end

      it "changes permission for the shared dir" do
        is_expected.to create_directory('/raid_shared_dir')
          .with(owner: 'root')
          .with(group: 'root')
          .with(mode: '1777')
      end
    end
  end
end

describe 'manage_raid:unmount' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:venv_path) { 'venv' }
      cached(:chef_run) do
        runner = ChefSpec::Runner.new(
          platform: platform, version: version,
          step_into: ['manage_raid']
        )
        allow_any_instance_of(Object).to receive(:cookbook_virtualenv_path).and_return(venv_path)
        runner.converge_dsl do
          manage_raid 'unmount' do
            action :unmount
            raid_vol_array %w(vol-0 vol-1)
            raid_shared_dir "raid_shared_dir"
            raid_type ' 0'
          end
        end
      end

      stubs_for_provider('manage_raid') do |resource|
        allow(resource).to receive(:get_raid_devices).with("/dev/md0").and_return("device1 device2")
      end

      it "unmounts and disables shared dir" do
        is_expected.to unmount_mount("/raid_shared_dir")
          .with(device: "/dev/md0")
          .with(fstype: "ext4")
          .with(options: %w(defaults nofail _netdev))
          .with(retries: 10)
          .with(retry_delay: 6)

        is_expected.to disable_mount("/raid_shared_dir")
          .with(device: "/dev/md0")
          .with(fstype: "ext4")
          .with(options: %w(defaults nofail _netdev))
          .with(retries: 10)
          .with(retry_delay: 6)
      end

      it "deletes shared dir" do
        is_expected.to delete_directory("/raid_shared_dir").with(recursive: true)
      end

      it "stops RAID device" do
        is_expected.to run_execute("Deactivate array, releasing all resources")
          .with(command: "mdadm --stop /dev/md0")
      end

      it "removes the superblocks" do
        is_expected.to run_execute("Erase the MD superblock from a device")
          .with(command: "mdadm --zero-superblock device1 device2")
      end

      it "removes RAID from /etc/mdadm.conf" do
        is_expected.to edit_delete_lines("Remove RAID from /etc/mdadm.conf")
          .with(path: "/etc/mdadm.conf")
          .with(pattern: "ARRAY /dev/md0 *")
      end

      it "detaches each volume" do
        is_expected.to run_execute("detach_raid_volume_0")
          .with(command: "#{venv_path}/bin/python /usr/local/sbin/manageVolume.py --volume-id vol-0 --detach")

        is_expected.to run_execute("detach_raid_volume_1")
          .with(command: "#{venv_path}/bin/python /usr/local/sbin/manageVolume.py --volume-id vol-1 --detach")
      end
    end
  end
end
