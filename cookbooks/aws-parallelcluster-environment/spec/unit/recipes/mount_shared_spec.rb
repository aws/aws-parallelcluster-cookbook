require 'spec_helper'

describe 'aws-parallelcluster-environment::mount_shared' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = runner(platform: platform, version: version) do |node|
          node.override['cluster']['head_node_private_ip'] = '0.0.0.0'
          node.override['cluster']['node_type'] = 'ComputeFleet'
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

      it 'mounts /opt/parallelcluster/shared' do
        is_expected.to mount_volume('mount /opt/parallelcluster/shared')
          .with(device: "0.0.0.0:/opt/parallelcluster/shared")
          .with(fstype: 'nfs')
          .with(options: 'hard,_netdev,noatime')
          .with(retries: 10)
          .with(retry_delay: 6)
      end
    end
  end
end
