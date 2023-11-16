require 'spec_helper'

class ConvergeManageEbs
  def self.mount(chef_run, shared_dirs:, volumes:)
    chef_run.converge_dsl do
      manage_ebs 'mount' do
        shared_dir_array shared_dirs
        vol_array volumes
        action :mount
      end
    end
  end

  def self.unmount(chef_run, shared_dirs:, volumes:)
    chef_run.converge_dsl do
      manage_ebs 'unmount' do
        shared_dir_array shared_dirs
        vol_array volumes
        action :unmount
      end
    end
  end

  def self.export(chef_run, shared_dirs:)
    chef_run.converge_dsl do
      manage_ebs 'export' do
        shared_dir_array shared_dirs
        action :export
      end
    end
  end

  def self.unexport(chef_run, shared_dirs:)
    chef_run.converge_dsl do
      manage_ebs 'unexport' do
        shared_dir_array shared_dirs
        action :unexport
      end
    end
  end

  def self.nothing(chef_run)
    chef_run.converge_dsl do
      manage_ebs 'nothing' do
        action :nothing
      end
    end
  end
end

describe 'manage_ebs:get_uuid' do
  cached(:chef_run) do
    ChefSpec::SoloRunner.new.converge_dsl do
      manage_ebs 'nothing' do
        action :nothing
      end
    end
  end
  cached(:resource) { chef_run.find_resource('manage_ebs', 'nothing') }
  let(:shellout) { double(run_command: nil, error!: nil, stdout: '', stderr: '', exitstatus: 0, live_stream: '') }
  cached(:device) { 'test_device' }
  cached(:expected_uuid) { 'test_uuid' }

  before do
    allow(resource).to receive_shell_out("blkid -c /dev/null #{device}").and_return(shellout)
  end

  it 'parses output and returns UUID' do
    allow(shellout).to receive(:stdout).and_return("   UUID=\"#{expected_uuid}\"  ")
    expect(resource.get_uuid(device)).to eq(expected_uuid)
  end

  it 'returns nil if no match is found' do
    allow(shellout).to receive(:stdout).and_return("   unexpected result  ")
    expect(resource.get_uuid(device)).to be(nil)
  end
end

describe 'manage_ebs:get_pt_type' do
  cached(:chef_run) do
    ChefSpec::SoloRunner.new.converge_dsl do
      manage_ebs 'nothing' do
        action :nothing
      end
    end
  end
  cached(:resource) { chef_run.find_resource('manage_ebs', 'nothing') }
  let(:shellout) { double(run_command: nil, error!: nil, stdout: '', stderr: '', exitstatus: 0, live_stream: '') }
  cached(:device) { 'test_device' }
  cached(:expected_pt_type) { 'test_pt_type' }

  before do
    allow(resource).to receive_shell_out("blkid -c /dev/null #{device}").and_return(shellout)
  end

  it 'parses output and returns pt type' do
    allow(shellout).to receive(:stdout).and_return("   PTTYPE=\"#{expected_pt_type}\"  ")
    expect(resource.get_pt_type(device)).to eq(expected_pt_type)
  end

  it 'returns nil if no match is found' do
    allow(shellout).to receive(:stdout).and_return("   unexpected result  ")
    expect(resource.get_pt_type(device)).to be(nil)
  end
end

describe 'manage_ebs:get_fs_type' do
  cached(:chef_run) do
    ChefSpec::SoloRunner.new.converge_dsl do
      manage_ebs 'nothing' do
        action :nothing
      end
    end
  end
  cached(:resource) { chef_run.find_resource('manage_ebs', 'nothing') }
  let(:shellout) { double(run_command: nil, error!: nil, stdout: '', stderr: '', exitstatus: 0, live_stream: '') }
  cached(:device) { 'test_device' }
  cached(:expected_fs_type) { 'test_fs_type' }

  before do
    allow(resource).to receive_shell_out("blkid -c /dev/null #{device}").and_return(shellout)
  end

  it 'parses output and returns fs type' do
    allow(shellout).to receive(:stdout).and_return("   TYPE=\"#{expected_fs_type}\"  ")
    expect(resource.get_fs_type(device)).to eq(expected_fs_type)
  end
  #
  # it 'returns nil if no match is found' do
  #   allow(shellout).to receive(:stdout).and_return("   unexpected result  ")
  #   expect(resource.get_fs_type(device)).to be(nil)
  # end
end

describe 'manage_ebs:get_1st_partition' do
  cached(:chef_run) do
    ChefSpec::SoloRunner.new.converge_dsl do
      manage_ebs 'nothing' do
        action :nothing
      end
    end
  end
  cached(:resource) { chef_run.find_resource('manage_ebs', 'nothing') }
  let(:shellout) { double(run_command: nil, error!: nil, stdout: 'aaa', stderr: '', exitstatus: 0, live_stream: '') }
  cached(:device) { 'test_device' }
  cached(:result) { 'test_result' }

  before do
    allow(resource).to receive_shell_out("lsblk -ln -o Name #{device}|awk 'NR==2'").and_return(shellout)
  end

  it 'returns first partition' do
    allow(shellout).to receive(:stdout).and_return(result)
    expect(resource.get_1st_partition(device)).to eq("/dev/#{result}")
  end
end

describe 'manage_ebs:mount' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:venv_path) { 'venv_path' }
      cached(:volume_fs_type) { 'test_volume_fs_type' }

      cached(:chef_run) do
        runner = runner(platform: platform, version: version, step_into: %w(manage_ebs volume)) do |node|
          node.override['cluster']['volume_fs_type'] = volume_fs_type
        end
        ConvergeManageEbs.mount(runner, shared_dirs: %w(ebs_shared_dir_0 ebs_shared_dir_1), volumes: %w(vol-0 vol-1))
      end

      before do
        stub_command("mount | grep ' /ebs_shared_dir_0 '").and_return(true)
        stub_command("mount | grep ' /ebs_shared_dir_1 '").and_return(false)
        allow_any_instance_of(Object).to receive(:cookbook_virtualenv_path).and_return(venv_path)
        stubs_for_resource('manage_ebs') do |res|
          allow(res).to receive(:lazy_uuid).with('/dev/disk/by-ebs-volumeid/vol-0').and_return('uuid-0')
          allow(res).to receive(:lazy_uuid).with('/dev/disk/by-ebs-volumeid/vol-1').and_return('uuid-1')
        end
      end

      it 'mounts manage_ebs' do
        is_expected.to mount_manage_ebs('mount')
      end

      it "attaches volumes" do
        is_expected.to attach_volume('attach volume 0').with_volume_id('vol-0')
        is_expected.to attach_volume('attach volume 1').with_volume_id('vol-1')
      end

      it "mounts volumes" do
        is_expected.to mount_volume('mount volume 0').with(
          shared_dir: 'ebs_shared_dir_0',
          device: 'uuid-0',
          fstype: volume_fs_type,
          device_type: :uuid,
          options: "_netdev",
          retries: 10,
          retry_delay: 6
        )
        is_expected.to mount_volume('mount volume 1').with(
          shared_dir: 'ebs_shared_dir_1',
          device: 'uuid-1',
          fstype: volume_fs_type,
          device_type: :uuid,
          options: "_netdev",
          retries: 10,
          retry_delay: 6
        )
      end
    end
  end
end

describe 'manage_ebs:unmount' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:venv_path) { 'venv' }
      cached(:chef_run) do
        runner = runner(platform: platform, version: version, step_into: ['manage_ebs'])
        allow_any_instance_of(Object).to receive(:cookbook_virtualenv_path).and_return(venv_path)
        ConvergeManageEbs.unmount(runner, shared_dirs: %w(ebs_shared_dir_0 ebs_shared_dir_1), volumes: %w(vol-0 vol-1))
      end

      before do
        stub_command("mount | grep ' /ebs_shared_dir_0 '").and_return(true)
        stub_command("mount | grep ' /ebs_shared_dir_1 '").and_return(false)
        allow_any_instance_of(Object).to receive(:cookbook_virtualenv_path).and_return(venv_path)
        stubs_for_resource('manage_ebs') do |res|
          allow(res).to receive(:lazy_uuid).with('/dev/disk/by-ebs-volumeid/vol-0').and_return('uuid-0')
          allow(res).to receive(:lazy_uuid).with('/dev/disk/by-ebs-volumeid/vol-1').and_return('uuid-1')
        end
      end

      it "unmounts volumes" do
        is_expected.to unmount_volume('unmount volume 0').with_shared_dir('ebs_shared_dir_0')
        is_expected.to unmount_volume('unmount volume 1').with_shared_dir('ebs_shared_dir_1')
      end

      it "detached volumes" do
        is_expected.to detach_volume('detach volume 0').with_volume_id('vol-0')
        is_expected.to detach_volume('detach volume 1').with_volume_id('vol-1')
      end
    end
  end
end

describe 'manage_ebs:export' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:cidr_list) { 'cidr_list' }
      cached(:chef_run) do
        runner = runner(platform: platform, version: version, step_into: ['manage_ebs'])
        ConvergeManageEbs.export(runner, shared_dirs: %w(ebs_shared_dir_0 ebs_shared_dir_1))
      end

      before do
        allow_any_instance_of(Object).to receive(:get_vpc_cidr_list).and_return(cidr_list)
      end

      it "exports volumes" do
        is_expected.to export_volume('export volume ebs_shared_dir_0').with(
          shared_dir: 'ebs_shared_dir_0'
        )
        is_expected.to export_volume('export volume ebs_shared_dir_1').with(
          shared_dir: 'ebs_shared_dir_1'
        )
      end
    end
  end
end

describe 'manage_ebs:unexport' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = runner(platform: platform, version: version, step_into: %w(manage_ebs volume))
        ConvergeManageEbs.unexport(runner, shared_dirs: %w(ebs_shared_dir_0 ebs_shared_dir_1))
      end

      it "unexports volumes" do
        is_expected.to unexport_volume('unexport volume ebs_shared_dir_0').with(
          shared_dir: 'ebs_shared_dir_0'
        )
        is_expected.to unexport_volume('unexport volume ebs_shared_dir_1').with(
          shared_dir: 'ebs_shared_dir_1'
        )
      end
    end
  end
end
