require 'spec_helper'

describe 'aws-parallelcluster-environment::ebs' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      context 'when HeadNode' do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['node_type'] = "HeadNode"
            node.override['cluster']['ebs_shared_dirs'] = "/shared,/test"
            node.override['cluster']['ebs_shared_dirs'] = "vol-1,vol2"
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it 'execute manage_ebs to mount ebs' do
          is_expected.to mount_manage_ebs('add ebs')
        end
      end

      context 'when ComputeFleet' do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['node_type'] = "ComputeFleet"
            node.override['cluster']['ebs_shared_dirs'] = "/shared,/test"
            node.override['cluster']['head_node_private_ip'] = '0.0.0.0'
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it 'mount volume /shared' do
          is_expected.to mount_volume('mount volume /shared').with(
            shared_dir: '/shared',
            fstype: 'nfs',
            options: "hard,_netdev,noatime",
            retries: 10,
            retry_delay: 6
          )
        end

        it 'mount volume /test' do
          is_expected.to mount_volume('mount volume /test').with(
            shared_dir: '/test',
            fstype: 'nfs',
            options: "hard,_netdev,noatime",
            retries: 10,
            retry_delay: 6
          )
        end
      end
    end
  end
end
