require 'spec_helper'

describe 'aws-parallelcluster-environment::login_nodes_keys' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      context "when awsbatch scheduler" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['scheduler'] = 'awsbatch'
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it 'does not create the script directory' do
          is_expected.to_not create_directory("#{node['cluster']['shared_dir_login_nodes']}/scripts")
        end
      end

      context "when compute node" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['node_type'] = 'ComputeFleet'
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it 'does not create the scripts directory' do
          is_expected.to_not create_directory("#{node['cluster']['shared_dir_login_nodes']}/scripts")
        end
      end

      context "when slurm scheduler and head node" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['node_type'] = 'HeadNode'
            node.override['cluster']['scheduler'] = 'slurm'
            node.override['cluster']['shared_dir_login_nodes'] = '/opt/parallelcluster/shared_login_nodes'
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it 'creates the scripts directory' do
          is_expected.to create_directory("#{node['cluster']['shared_dir_login_nodes']}/scripts").with(
            owner: 'root',
            group: 'root',
            mode:  '0744'
          )
        end

        it 'creates keys-manager.sh script' do
          is_expected.to create_cookbook_file("#{node['cluster']['shared_dir_login_nodes']}/scripts/keys-manager.sh").with(
            source: 'login_nodes/keys-manager.sh',
            owner: "root",
            group: "root",
            mode: "0744"
          )
        end

        it "creates login nodes keys" do
          is_expected.to run_execute("Initialize Login Nodes keys")
            .with(command: "bash #{node['cluster']['shared_dir_login_nodes']}/scripts/keys-manager.sh --create --folder-path #{node['cluster']['shared_dir_login_nodes']}")
        end
      end

      context "when slurm scheduler and login node" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['node_type'] = 'LoginNode'
            node.override['cluster']['scheduler'] = 'slurm'
            node.override['cluster']['shared_dir_login_nodes'] = '/opt/parallelcluster/shared_login_nodes'
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it "imports login nodes keys" do
          is_expected.to run_execute("Import Login Nodes keys")
            .with(command: "bash #{node['cluster']['shared_dir_login_nodes']}/scripts/keys-manager.sh --import --folder-path #{node['cluster']['shared_dir_login_nodes']}")
        end
      end
    end
  end
end
