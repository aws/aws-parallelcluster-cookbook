require 'spec_helper'

describe 'aws-parallelcluster-computefleet::clusterstatusmgtd_config' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = runner(platform: platform, version: version) do |node|
          node.override['cluster']['node_type'] = 'HeadNode'
          node.override['cluster']['scheduler'] = 'slurm'
        end
        runner.converge(described_recipe)
      end
      cached(:node) { chef_run.node }

      it 'creates computefleet-status.json file' do
        is_expected.to create_file("#{node['cluster']['shared_dir']}/computefleet-status.json")
          .with(user: "#{node['cluster']['cluster_admin_user']}")
          .with(group: "#{node['cluster']['cluster_admin_user']}")
          .with(mode: '0755')
      end

      it 'creates the clusterstatusmgtd file with the correct attributes' do
        is_expected.to create_template('/etc/sudoers.d/99-parallelcluster-clusterstatusmgtd')
          .with(source: 'clusterstatusmgtd/99-parallelcluster-clusterstatusmgtd.erb')
          .with(user: 'root')
          .with(group: 'root')
          .with(mode: '0600')
      end

      it 'has the correct content' do
        is_expected.to render_file('/etc/sudoers.d/99-parallelcluster-clusterstatusmgtd')
          .with_content("#{node['cluster']['cluster_admin_user']} ALL = (root) NOPASSWD: CINC_COMMAND")
      end

      it 'creates clusterstatusmgtd log file' do
        is_expected.to create_file("#{node['cluster']['log_base_dir']}/clusterstatusmgtd")
          .with(user: 'root')
          .with(group: 'root')
          .with(mode: '0640')
      end
    end
  end
end
