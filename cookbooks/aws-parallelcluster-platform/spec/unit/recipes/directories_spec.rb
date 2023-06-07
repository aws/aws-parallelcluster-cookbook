require 'spec_helper'

describe 'aws-parallelcluster-platform::directories' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner(platform: platform, version: version).converge(described_recipe)
      end
      cached(:node) { chef_run.node }

      it 'creates parallelcluster directory' do
        is_expected.to create_directory(node['cluster']['etc_dir'])
      end

      it 'creates base directory' do
        is_expected.to create_directory(node['cluster']['base_dir'])
      end

      it 'creates sources directory' do
        is_expected.to create_directory(node['cluster']['sources_dir'])
      end

      it 'creates scripts directory' do
        is_expected.to create_directory(node['cluster']['scripts_dir'])
      end

      it 'creates license directory' do
        is_expected.to create_directory(node['cluster']['license_dir'])
      end

      it 'creates config directory' do
        is_expected.to create_directory(node['cluster']['configs_dir'])
      end

      it 'creates shared directory' do
        is_expected.to create_directory(node['cluster']['shared_dir'])
      end

      it 'creates log directory' do
        is_expected.to create_directory(node['cluster']['log_base_dir']).with(
          owner: 'root',
          mode: '1777',
          recursive: true
        )
      end
    end
  end
end
