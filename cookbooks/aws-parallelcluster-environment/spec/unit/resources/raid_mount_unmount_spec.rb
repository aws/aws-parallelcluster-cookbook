require 'spec_helper'

class Chef::Resource::RubyBlock
  def wait_for_block_dev(_path)
    # do nothing
  end
end

describe 'raid:mount' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:venv_path) { 'venv' }
      cached(:raid_superblock_version) do
        platform == 'redhat' || "#{platform}#{version}" == 'ubuntu20.04' || "#{platform}#{version}" == 'ubuntu22.04' ? '1.2' : '0.90'
      end
      cached(:chef_run) do
        runner = runner(
          platform: platform, version: version,
          step_into: ['raid']
        )
        allow_any_instance_of(Object).to receive(:cookbook_virtualenv_path).and_return(venv_path)
        runner.converge_dsl do
          raid 'mount' do
            action :mount
            raid_vol_array %w(vol-0 vol-1)
            raid_shared_dir "raid_shared_dir"
            raid_type ' 0'
          end
        end
      end

      it "attaches volumes" do
        is_expected.to attach_volume('attach raid volume 0').with_volume_id('vol-0')
        is_expected.to attach_volume('attach raid volume 1').with_volume_id('vol-1')
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

      it "mounts volume" do
        is_expected.to mount_volume('mount raid volume').with(
          shared_dir: 'raid_shared_dir',
          device: "/dev/md0",
          fstype: "ext4",
          options: "defaults,nofail,_netdev",
          retries: 10,
          retry_delay: 6
        )
      end
    end
  end
end

describe 'raid:unmount' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:venv_path) { 'venv' }
      cached(:chef_run) do
        runner = runner(
          platform: platform, version: version,
          step_into: ['raid']
        )
        allow_any_instance_of(Object).to receive(:cookbook_virtualenv_path).and_return(venv_path)
        runner.converge_dsl do
          raid 'unmount' do
            action :unmount
            raid_vol_array %w(vol-0 vol-1)
            raid_shared_dir "raid_shared_dir"
            raid_type ' 0'
          end
        end
      end

      stubs_for_provider('raid') do |resource|
        allow(resource).to receive(:get_raid_devices).with("/dev/md0").and_return("device1 device2")
      end

      it "unmounts volume" do
        is_expected.to unmount_volume('unmount raid volume').with_shared_dir('raid_shared_dir')
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

      it "detaches volume" do
        is_expected.to detach_volume('detach raid volume 0').with_volume_id('vol-0')
        is_expected.to detach_volume('detach raid volume 1').with_volume_id('vol-1')
      end
    end
  end
end
