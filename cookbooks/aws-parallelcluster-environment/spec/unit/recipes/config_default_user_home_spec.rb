require 'spec_helper'

describe 'aws-parallelcluster-environment::config_default_user_home' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      context 'when local' do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['default_user_home'] = "local"
            node.override['cluster']['cluster_user_home'] = "/home/user"
            node.override['cluster']['cluster_user_local_home'] = "/local/home/user"
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it 'runs the recipe' do
          is_expected.to run_bash("Backup /home/user")
          is_expected.to run_bash("Move /home/user")
          expect(chef_run.node['cluster']['cluster_user_home']).to eq('/local/home/user')
        end
      end
      context 'when shared' do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['default_user_home'] = "shared"
            node.override['cluster']['cluster_user_home'] = "/home/user"
            node.override['cluster']['cluster_user_local_home'] = "/local/home/user"
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it 'skips the recipe' do
          is_expected.not_to run_bash("Backup /home/user")
          is_expected.not_to run_bash("Move /home/user")
          expect(chef_run.node['cluster']['cluster_user_home']).to eq('/home/user')
        end
      end
    end
  end
end
