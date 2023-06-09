require 'spec_helper'

describe 'aws-parallelcluster-environment::mount_shared' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = runner(platform: platform, version: version) do |node|
          node.override['cluster']['head_node_private_ip'] = '0.0.0.0'
        end
        runner.converge(described_recipe)
      end
      cached(:node) { chef_run.node }

      it 'mounts /home' do
        is_expected.to mount_mount('/home')
          .with(device: "0.0.0.0:/home")
          .with(fstype: 'nfs')
          .with(options: %W(hard _netdev noatime))
          .with(retries: 10)
          .with(retry_delay: 6)

        is_expected.to enable_mount('/home')
      end

      it 'mounts /opt/parallelcluster/shared' do
        is_expected.to mount_mount('/opt/parallelcluster/shared')
          .with(device: "0.0.0.0:/opt/parallelcluster/shared")
          .with(fstype: 'nfs')
          .with(options: %W(hard _netdev noatime))
          .with(retries: 10)
          .with(retry_delay: 6)

        is_expected.to enable_mount('/opt/parallelcluster/shared')
      end
    end
  end
end
