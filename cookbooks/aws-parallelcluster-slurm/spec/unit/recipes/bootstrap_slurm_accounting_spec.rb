require 'spec_helper'

describe 'aws-parallelcluster-slurm::bootstrap_slurm_accounting' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = runner(platform: platform, version: version)
        runner.converge(described_recipe)
      end
      cached(:node) { chef_run.node }

      it "waits for cluster registration" do
        is_expected.to run_execute("wait for cluster registration").with(
          command: "#{node['cluster']['slurm']['install_dir']}/bin/sacctmgr show clusters -Pn cluster=#{node['cluster']['stack_name']} format=cluster | grep -Fx '#{node['cluster']['stack_name']}'"
        )
      end

      it "bootstraps the Slurm database with users" do
        is_expected.to run_bash("bootstrap slurm database")
      end
    end
  end
end
