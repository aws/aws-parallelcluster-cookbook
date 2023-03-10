require 'spec_helper'

def mock_get_vpc_cidr_list(cidr)
  allow_any_instance_of(Object).to receive(:get_vpc_cidr_list).and_return(cidr)
end

describe 'manage_raid:export' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = ChefSpec::Runner.new(
          platform: platform, version: version,
          step_into: ['manage_raid']
        )
        runner.converge_dsl do
          manage_raid 'export' do
            action :export
            raid_vol_array "vol-0, vol-1"
            raid_shared_dir "raid_shared_dir"
          end
        end
      end

      before do
        mock_get_vpc_cidr_list('0.0.0.0/0
                              192.168.200.4/30')
      end
      it "exports shared dir" do
        is_expected.to create_nfs_export("/raid_shared_dir")
          .with(network: get_vpc_cidr_list)
          .with(writeable: true)
          .with(options: %w(no_root_squash))
      end
    end
  end
end

describe 'manage_raid:unexport' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = ChefSpec::Runner.new(
          platform: platform, version: version,
          step_into: ['manage_raid']
        )
        runner.converge_dsl do
          manage_raid 'unexport' do
            action :unexport
            raid_vol_array "vol-0, vol-1"
            raid_shared_dir "raid_shared_dir"
          end
        end
      end

      it "unexports raid directory via NFS" do
        is_expected.to edit_delete_lines("remove volume from /etc/exports")
          .with(path: "/etc/exports")
          .with(pattern: "/raid_shared_dir *")
      end

      it "unexports volume" do
        is_expected.to run_execute("unexport volume").with(command: "exportfs -ra")
      end
    end
  end
end
