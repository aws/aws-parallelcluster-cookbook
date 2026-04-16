require 'spec_helper'

describe 'aws-parallelcluster-slurm::bootstrap_slurm_accounting' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      let(:accounting_cluster_name) { 'My-Custom-ClusterName' }

      before do
        allow_any_instance_of(Object).to receive(:get_slurm_accounting_cluster_name).and_return(accounting_cluster_name)
      end

      cached(:chef_run) do
        runner(platform: platform, version: version).converge(described_recipe)
      end
      cached(:node) { chef_run.node }

      it "waits for cluster registration using the name returned by get_slurm_accounting_cluster_name" do
        is_expected.to run_execute("wait for cluster registration")
        command = chef_run.execute("wait for cluster registration").command
        expect(command).to include("cluster=#{accounting_cluster_name}")
        expect(command).to include("grep -Fxi '#{accounting_cluster_name}'")
      end

      it "bootstraps the Slurm database using the name returned by get_slurm_accounting_cluster_name" do
        is_expected.to run_bash("bootstrap slurm database")
        code = chef_run.bash("bootstrap slurm database").code
        expect(code).to include("CLUSTER_NAME=#{accounting_cluster_name}")
      end
    end
  end
end
