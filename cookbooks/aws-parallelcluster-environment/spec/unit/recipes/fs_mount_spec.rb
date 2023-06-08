require 'spec_helper'

describe 'aws-parallelcluster-environment::fs_mount' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = runner(
          platform: platform, version: version
        ) do |node|
          node.override['cluster']['fsx_fs_ids'] = "lustre_id_1,lustre_id_2"
        end
        runner.converge(described_recipe)
      end
      cached(:node) { chef_run.node }

      describe 'call the efs for mounting' do
        it { is_expected.to mount_efs('mount efs') }
      end
      describe 'call the lustre for mounting' do
        it { is_expected.to mount_lustre("mount fsx") }
      end
    end
  end
end
