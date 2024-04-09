require 'spec_helper'

class Chef::Resource::RubyBlock
  def wait_for_block_dev(_path)
    # do nothing
  end
end

describe 'volume:mount' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      context "when not yet mounted" do
        cached(:chef_run) do
          runner = ChefSpec::Runner.new(platform: platform, version: version, step_into: ['volume'])
          runner.converge_dsl do
            volume 'mount' do
              shared_dir 'SHARED_DIR'
              device 'DEVICE'
              fstype 'FSTYPE'
              options %w(option1 option2)
              device_type :uuid
              retries 100
              retry_delay 200
              action :mount
            end
          end
        end

        before do
          stub_command("mount | grep ' /SHARED_DIR '").and_return(false)
        end

        it 'creates shared directory' do
          is_expected.to create_directory('/SHARED_DIR')
            .with(owner: 'root')
            .with(group: 'root')
            .with(mode: '1777')
          # .with(recursive: true) # even if we set recursive a true, the test fails
        end

        it 'mounts shared dir' do
          is_expected.to mount_mount('/SHARED_DIR')
            .with(device: 'DEVICE')
            .with(fstype: 'FSTYPE')
            .with(device_type: :uuid)
            .with(dump: 0)
            .with(pass: 0)
            .with(options: %w(option1 option2))
            .with(retries: 100)
            .with(retry_delay: 200)
        end

        it 'enables shared dir' do
          is_expected.to enable_mount('/SHARED_DIR')
            .with(device: 'DEVICE')
            .with(fstype: 'FSTYPE')
            .with(dump: 0)
            .with(pass: 0)
            .with(options: %w(option1 option2))
            .with(retries: 100)
            .with(retry_delay: 200)
        end

        it 'changes permissions' do
          is_expected.to create_directory('/SHARED_DIR')
            .with(path: '/SHARED_DIR')
            .with(owner: 'root')
            .with(group: 'root')
            .with(mode: '1777')
        end
      end

      context "when mounted and some properties are not set" do
        cached(:chef_run) do
          runner = ChefSpec::Runner.new(platform: platform, version: version, step_into: ['volume'])
          runner.converge_dsl do
            volume 'mount' do
              shared_dir '/SHARED_DIR'
              device 'DEVICE'
              fstype 'FSTYPE'
              options %w(option1 option2)
              action :mount
            end
          end
        end
        before do
          stub_command("mount | grep ' /SHARED_DIR '").and_return(true)
        end

        it 'creates shared directory' do
          is_expected.to create_directory('/SHARED_DIR')
            .with(owner: 'root')
            .with(group: 'root')
            .with(mode: '1777')
          # .with(recursive: true) # even if we set recursive a true, the test fails
        end

        it 'does not mount shared dir with default values' do
          is_expected.not_to mount_mount('/SHARED_DIR')
        end

        it 'enables shared dir' do
          is_expected.not_to enable_mount('/SHARED_DIR')
        end

        it 'changes permissions' do
          is_expected.to create_directory('/SHARED_DIR')
            .with(path: '/SHARED_DIR')
            .with(owner: 'root')
            .with(group: 'root')
            .with(mode: '1777')
        end
      end
    end
  end
end

describe 'volume:unmount' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      context "when not mounted" do
        cached(:chef_run) do
          runner = ChefSpec::Runner.new(
            platform: platform, version: version,
            step_into: ['volume']
          )
          runner.converge_dsl do
            volume 'unmount' do
              shared_dir 'SHARED_DIR'
              action :unmount
            end
          end
        end

            before do
              stub_command("mount | grep ' /SHARED_DIR '").and_return(false)
              allow(Dir).to receive(:empty?).with("/SHARED_DIR").and_return(is_dir_empty)
            end

            it 'does not unmount volume' do
              is_expected.not_to run_execute('unmount volume')
            end

            it "removes volume /SHARED_DIR from /etc/fstab" do
              is_expected.to edit_delete_lines("remove volume /SHARED_DIR from /etc/fstab")
                .with(path: "/etc/fstab")
                .with(pattern: " /SHARED_DIR ")
            end

            it "deletes shared dir only if empty" do
              if is_dir_empty
                is_expected.to delete_directory('/SHARED_DIR')
                  .with(recursive: false)
              else
                is_expected.not_to delete_directory('/SHARED_DIR')
              end
            end
          end
        end
      end

      context "when mounted" do
        cached(:chef_run) do
          runner = ChefSpec::Runner.new(
            platform: platform, version: version,
            step_into: ['volume']
          )
          runner.converge_dsl do
            volume 'unmount' do
              shared_dir '/SHARED_DIR'
              action :unmount
            end
          end
        end

            before do
              stub_command("mount | grep ' /SHARED_DIR '").and_return(true)
              allow(Dir).to receive(:empty?).with("/SHARED_DIR").and_return(is_dir_empty)
            end

        it 'unmounts volume' do
          is_expected.to run_execute('unmount volume')
            .with(command: "umount -fl /SHARED_DIR")
        end

            it "removes volume /SHARED_DIR from /etc/fstab" do
              is_expected.to edit_delete_lines("remove volume /SHARED_DIR from /etc/fstab")
                .with(path: "/etc/fstab")
                .with(pattern: " /SHARED_DIR ")
            end

            it "deletes shared dir only if empty" do
              if is_dir_empty
                is_expected.to delete_directory('/SHARED_DIR')
                  .with(recursive: false)
              else
                is_expected.not_to delete_directory('/SHARED_DIR')
              end
            end
          end
        end
      end
    end
  end
end

describe 'volume:attach' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = ChefSpec::Runner.new(
          platform: platform, version: version,
          step_into: ['volume']
        ) do |node|
          node.override['cluster']['cookbook_virtualenv_path'] = '/cookbook_venv'
        end
        runner.converge_dsl do
          volume 'attach' do
            volume_id 'volumeid'
            action :attach
          end
        end
      end

      it 'waits for the block device to be ready to attach the volume' do
        block = chef_run.find_resource('ruby_block', 'sleeping_for_volume_volumeid')
        expect(block).to receive(:wait_for_block_dev).with('/dev/disk/by-ebs-volumeid/volumeid')
        block.block.call
        expect(block).to subscribe_to('execute[attach_volume_volumeid]').on(:run).immediately
      end

      it 'attaches the volume' do
        is_expected.to run_execute('attach_volume_volumeid')
          .with(command: "/cookbook_venv/bin/python /usr/local/sbin/manageVolume.py --volume-id volumeid --attach")
          .with(creates: '/dev/disk/by-ebs-volumeid/volumeid')
      end
    end
  end
end

describe 'volume:detach' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = ChefSpec::Runner.new(
          platform: platform, version: version,
          step_into: ['volume']
        ) do |node|
          node.override['cluster']['cookbook_virtualenv_path'] = '/cookbook_venv'
        end
        runner.converge_dsl do
          volume 'detach' do
            volume_id 'volumeid'
            action :detach
          end
        end
      end

      it 'detaches the volume' do
        is_expected.to run_execute('detach_volume_volumeid')
          .with(command: "/cookbook_venv/bin/python /usr/local/sbin/manageVolume.py --volume-id volumeid --detach")
      end
    end
  end
end

describe 'volume:export' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:vpc_cidr_list) { 'vpc_cidr_list' }
      cached(:chef_run) do
        runner = ChefSpec::Runner.new(
          platform: platform, version: version,
          step_into: ['volume']
        )
        runner.converge_dsl do
          volume 'export' do
            shared_dir 'raid_shared_dir '
            action :export
          end
        end
      end

      before do
        allow_any_instance_of(Object).to receive(:get_vpc_cidr_list).and_return(vpc_cidr_list)
      end

      it 'exports shared dir' do
        is_expected.to create_nfs_export("/raid_shared_dir")
          .with(network: vpc_cidr_list)
          .with(writeable: true)
          .with(options: %w(no_root_squash))
      end
    end
  end
end

describe 'volume:unexport' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = ChefSpec::Runner.new(
          platform: platform, version: version,
          step_into: ['volume']
        )
        runner.converge_dsl do
          volume 'unexport' do
            shared_dir 'raid_shared_dir '
            action :unexport
          end
        end
      end

      it 'deletes shared dir from /etc/exports' do
        is_expected.to edit_delete_lines("remove volume from /etc/exports")
          .with(path: "/etc/exports")
          .with(pattern: "^/raid_shared_dir *")
      end

      it 'unexports volume' do
        is_expected.to run_execute("unexport volume")
          .with(command: "exportfs -ra")
      end
    end
  end
end
