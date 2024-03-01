require 'spec_helper'

describe 'aws-parallelcluster-environment::login_nodes_keys' do
  SHARED_DIR_LOGIN_NODES = "/SHARED_DIR_LOGIN_NODES".freeze
  SYNC_FILE = "#{SHARED_DIR_LOGIN_NODES}/.login_nodes_keys_sync_file".freeze
  CLUSTER_CONFIG_VERSION = "CLUSTER_CONFIG_VERSION".freeze

  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      context "when awsbatch scheduler" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['scheduler'] = 'awsbatch'
            node.override['cluster']['shared_dir_login_nodes'] = SHARED_DIR_LOGIN_NODES
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it 'does not create the script directory' do
          is_expected.to_not create_directory("#{SHARED_DIR_LOGIN_NODES}/scripts")
        end
      end

      context "when compute node" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['node_type'] = 'ComputeFleet'
            node.override['cluster']['shared_dir_login_nodes'] = SHARED_DIR_LOGIN_NODES
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it 'does not create the scripts directory' do
          is_expected.to_not create_directory("#{SHARED_DIR_LOGIN_NODES}/scripts")
        end
      end

      context "when slurm scheduler and head node" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['node_type'] = 'HeadNode'
            node.override['cluster']['scheduler'] = 'slurm'
            node.override['cluster']['shared_dir_login_nodes'] = SHARED_DIR_LOGIN_NODES
            node.override['cluster']['cluster_config_version'] = CLUSTER_CONFIG_VERSION
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it 'creates the scripts directory' do
          is_expected.to create_directory("#{SHARED_DIR_LOGIN_NODES}/scripts").with(
            owner: 'root',
            group: 'root',
            mode:  '0744'
          )
        end

        it 'creates keys-manager.sh script' do
          is_expected.to create_cookbook_file("#{SHARED_DIR_LOGIN_NODES}/scripts/keys-manager.sh").with(
            source: 'login_nodes/keys-manager.sh',
            owner: "root",
            group: "root",
            mode: "0744"
          )
        end

        it "creates login nodes keys" do
          is_expected.to run_execute("Initialize Login Nodes keys")
            .with(command: "bash #{SHARED_DIR_LOGIN_NODES}/scripts/keys-manager.sh --create --folder-path #{SHARED_DIR_LOGIN_NODES}")
        end

        it "writes the synchronization file for login nodes" do
          is_expected.to create_file(SYNC_FILE).with(
            content: CLUSTER_CONFIG_VERSION,
            mode: '0644',
            owner: 'root',
            group: 'root'
          )
        end
      end

      context "when slurm scheduler and login node" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['node_type'] = 'LoginNode'
            node.override['cluster']['scheduler'] = 'slurm'
            node.override['cluster']['shared_dir_login_nodes'] = SHARED_DIR_LOGIN_NODES
            node.override['cluster']['cluster_config_version'] = CLUSTER_CONFIG_VERSION
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it "waits for cluster config version file" do
          is_expected.to run_bash("Wait for synchronization file at #{SYNC_FILE} to be written for version #{CLUSTER_CONFIG_VERSION}").with(
            code: "[[ \"$(cat #{SYNC_FILE})\" == \"#{CLUSTER_CONFIG_VERSION}\" ]] || exit 1",
            retries: 30,
            retry_delay: 10,
            timeout: 5
          )
        end

        it "imports login nodes keys" do
          is_expected.to run_execute("Import Login Nodes keys")
            .with(command: "bash #{SHARED_DIR_LOGIN_NODES}/scripts/keys-manager.sh --import --folder-path #{SHARED_DIR_LOGIN_NODES}")
        end
      end
    end
  end
end
