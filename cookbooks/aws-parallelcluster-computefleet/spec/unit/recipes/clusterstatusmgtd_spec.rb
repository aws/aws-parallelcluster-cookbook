require 'spec_helper'

describe 'aws-parallelcluster-computefleet::clusterstatusmgtd' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner(platform: platform, version: version).converge(described_recipe)
      end
      cached(:node) { chef_run.node }

      it 'creates scripts directory' do
        is_expected.to create_directory(node['cluster']['scripts_dir']).with(recursive: true)
      end

      it 'creates clusterstatusmgtd file' do
        is_expected.to create_cookbook_file("#{node['cluster']['scripts_dir']}/clusterstatusmgtd.py")
          .with(source: 'clusterstatusmgtd/clusterstatusmgtd.py')
          .with(user: 'root')
          .with(group: 'root')
          .with(mode: '0755')
      end

      it 'creates clusterstatusmgtd_logging.conf file' do
        is_expected.to create_cookbook_file("#{node['cluster']['scripts_dir']}/clusterstatusmgtd_logging.conf")
          .with(source: 'clusterstatusmgtd/clusterstatusmgtd_logging.conf')
          .with(user: 'root')
          .with(group: 'root')
          .with(mode: '0755')
      end
    end
  end
end
