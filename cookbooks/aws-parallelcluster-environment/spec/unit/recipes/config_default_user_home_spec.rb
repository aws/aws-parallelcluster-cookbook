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
          is_expected.to stop_service("sshd")
          is_expected.to run_bash("Close ssh connections to perform a default user move")
          is_expected.to run_bash("Backup /home/user")
          is_expected.to run_bash("Move /home/user")
          expect(chef_run.node['cluster']['cluster_user_home']).to eq('/local/home/user')
          is_expected.to start_service("sshd")
        end

        it 'moves the cluster user home directory with data integrity check' do
          user_home = "/home/user"
          user_local_home = "/local/home/user"
          expect(chef_run).to run_bash("Verify data integrity for #{user_home}").with(
            code: <<-CODE
    diff_output=$(diff -r #{user_home} #{user_local_home})
    diff_exit_code=$?
    if [ $diff_exit_code -eq 0 ]; then
      rm -rf /tmp#{user_home}
      rm -rf #{user_home}
    else
      echo "Data integrity check failed comparing #{user_local_home} and #{user_home}: $diff_output" >&2
      exit 1
    fi
            CODE
          )
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
