require 'spec_helper'

describe 'aws-parallelcluster-platform::users' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        ChefSpec::Runner.new(platform: platform, version: version).converge(described_recipe)
      end
      cached(:node) { chef_run.node }

      it 'creates admin group' do
        is_expected.to create_group(node['cluster']['cluster_admin_group']).with(
          comment: 'AWS ParallelCluster Admin group',
          gid: node['cluster']['cluster_admin_group_id'],
          system: true
        )
      end

      it 'creates admin user' do
        is_expected.to create_user(node['cluster']['cluster_admin_user']).with(
          comment: 'AWS ParallelCluster Admin user',
          uid: node['cluster']['cluster_admin_user_id'],
          gid: node['cluster']['cluster_admin_group_id'],
          system: true,
          shell: '/bin/bash',
          home: "/home/#{node['cluster']['cluster_admin_user']}",
          manage_home: false
        )
      end

      it 'sets user ulimit' do
        is_expected.to create_user_ulimit('*')
          .with_filehandle_limit(node['cluster']['filehandle_limit'])
      end
    end
  end
end
