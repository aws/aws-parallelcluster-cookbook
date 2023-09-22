require 'spec_helper'

describe 'aws-parallelcluster-environment::mount_internal_use_fs' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = runner(platform: platform, version: version) do |node|
          node.override['cluster']['head_node_private_ip'] = '0.0.0.0'
          node.override['cluster']['node_type'] = 'ComputeFleet'
          node.override['cluster']['internal_shared_dirs'] = %w(/opt/slurm /opt/intel)
          node.override['cluster']['efs_shared_dirs'] = "/opt/slurm,/opt/intel"
        end
        runner.converge(described_recipe)
      end
      cached(:node) { chef_run.node }

      it 'mounts /home' do
        is_expected.to mount_volume('mount /home')
          .with(device: "0.0.0.0:/home")
          .with(fstype: 'nfs')
          .with(options: 'hard,_netdev,noatime')
          .with(retries: 10)
          .with(retry_delay: 6)
      end

      describe 'call efs for mounting' do
        it { is_expected.to mount_efs('mount internal use efs') }
      end
    end
  end
end
