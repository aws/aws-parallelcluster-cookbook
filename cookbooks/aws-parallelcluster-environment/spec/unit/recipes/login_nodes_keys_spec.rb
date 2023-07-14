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

        it 'does not create login_nodes directory' do
          is_expected.to_not create_directory("#{node['cluster']['scripts_dir']}/login_nodes")
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

        it 'does not create login_nodes directory' do
          is_expected.to_not create_directory("#{node['cluster']['scripts_dir']}/login_nodes")
        end
      end

      context "when slurm scheduler and head node" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['node_type'] = 'HeadNode'
            node.override['cluster']['scheduler'] = 'slurm'
            node.override['cluster']['shared_dir_login_nodes'] = '/opt/shared_login_nodes'
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it 'creates the login_nodes directory' do
          is_expected.to create_directory("#{node['cluster']['scripts_dir']}/login_nodes").with(
            owner: 'root',
            group: 'root',
            mode:  '0744'
          )
        end

        it 'creates keys-manager.sh script' do
          is_expected.to create_cookbook_file("#{node['cluster']['scripts_dir']}/login_nodes/keys-manager.sh").with(
            source: 'login_nodes/keys-manager.sh',
            owner: "root",
            group: "root",
            mode: "0744"
          )
        end

        it "exports keys_manager_script_dir" do
          is_expected.to export_volume('export keys_manager_script_dir').with(
            shared_dir: "#{node['cluster']['scripts_dir']}/login_nodes"
          )
        end

        it "creates login nodes keys" do
          is_expected.to run_execute("Initialize Login Nodes keys")
            .with(command: "bash #{node['cluster']['scripts_dir']}/login_nodes/keys-manager.sh --create --folder-path #{node['cluster']['shared_dir_login_nodes']}")
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

        it 'creates the login_nodes directory' do
          is_expected.to create_directory("#{node['cluster']['scripts_dir']}/utils").with(
            owner: 'root',
            group: 'root',
            mode:  '0744'
          )
        end

        it 'mount keys_manager_script_dir' do
          is_expected.to mount_volume('mount keys_manager_script_dir').with(
            shared_dir: "#{node['cluster']['scripts_dir']}/utils",
            fstype: 'nfs',
            options: "hard,_netdev,noatime",
            retries: 10,
            retry_delay: 6
          )
        end

        it "import login nodes keys" do
          is_expected.to run_execute("Import Login Nodes keys")
            .with(command: "bash #{node['cluster']['scripts_dir']}/utils/keys-manager.sh --import --folder-path #{node['cluster']['shared_dir_login_nodes']}")
        end
      end
    end
  end
end
