require 'spec_helper'

describe 'aws-parallelcluster-slurm::clear_slurm_accounting' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = runner(platform: platform, version: version) do |node|
          mock_file_exists("/var/spool/slurm.state/clustername", true)
          node.override['cluster']['slurmdbd_service_enabled'] = true
        end
        runner.converge(described_recipe)
      end
      cached(:node) { chef_run.node }

      it 'stops the slurm database daemon' do
        is_expected.to disable_service("slurmdbd")
      end

      it 'deletes the Slurm database password update script' do
        is_expected.to delete_file("#{node['cluster']['scripts_dir']}/slurm/update_slurm_database_password.sh")
      end

      it 'Removes existing cluster name state file' do
        is_expected.to delete_file('/var/spool/slurm.state/clustername')
      end
    end
  end
end
