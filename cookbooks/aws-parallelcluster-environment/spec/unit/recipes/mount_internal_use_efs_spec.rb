require 'spec_helper'

describe 'aws-parallelcluster-environment::mount_internal_use_efs' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = runner(platform: platform, version: version) do |node|
          node.override['cluster']['head_node_private_ip'] = '0.0.0.0'
          node.override['cluster']['node_type'] = 'ComputeFleet'
          node.override['cluster']['internal_shared_dirs'] = %w(/opt/slurm /opt/intel)
          node.override['cluster']['efs_shared_dirs'] = "/opt/parallelcluster/init_shared"
        end
        runner.converge(described_recipe)
      end
      cached(:node) { chef_run.node }

      describe 'call efs for mounting' do
        it { is_expected.to mount_efs('mount internal shared efs') }
      end

      context "when node type is HeadNode" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['head_node_private_ip'] = '0.0.0.0'
            node.override['cluster']['node_type'] = 'HeadNode'
            node.override['cluster']['internal_shared_dirs'] = %w(/opt/slurm /opt/intel)
            node.override['cluster']['efs_shared_dirs'] = "/opt/parallelcluster/init_shared"
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        describe 'restore internal use shared data with integrity check' do
          it 'restores internal shared dirs with data integrity check' do
            chef_run.node['cluster']['internal_shared_dirs'].each do |dir|
              expect(chef_run).to run_bash("Restore #{dir}").with(
                code: <<-CODE
        rsync -a --ignore-existing /tmp#{dir}/ #{dir}
        diff_output=$(diff -r /tmp#{dir}/ #{dir})
        if [[ $diff_output != *"Only in /tmp#{dir}"* ]]; then
          rm -rf /tmp#{dir}/
        else
          only_in_tmp=$(echo "$diff_output" | grep "Only in /tmp#{dir}")
          echo "Data integrity check failed comparing #{dir} and /tmp#{dir}. Differences:"
          echo "$only_in_tmp"
          exit 1
        fi
            CODE
              )
            end
          end
        end
      end
    end
  end
end
