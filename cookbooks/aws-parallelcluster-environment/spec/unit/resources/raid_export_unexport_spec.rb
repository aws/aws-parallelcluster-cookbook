require 'spec_helper'

def mock_get_vpc_cidr_list(cidr)
  allow_any_instance_of(Object).to receive(:get_vpc_cidr_list).and_return(cidr)
end

describe 'raid:export' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = runner(
          platform: platform, version: version,
          step_into: ['raid']
        )
        runner.converge_dsl do
          raid 'export' do
            action :export
            raid_shared_dir "raid_shared_dir"
          end
        end
      end

      it "exports volume" do
        is_expected.to export_volume('export volume raid_shared_dir').with(
          shared_dir: 'raid_shared_dir'
        )
      end
    end
  end
end

describe 'raid:unexport' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = runner(
          platform: platform, version: version,
          step_into: ['raid']
        )
        runner.converge_dsl do
          raid 'unexport' do
            action :unexport
            raid_shared_dir "raid_shared_dir"
          end
        end
      end

      it "unexports volume" do
        is_expected.to unexport_volume('unexport volume raid_shared_dir').with(
          shared_dir: 'raid_shared_dir'
        )
      end
    end
  end
end
