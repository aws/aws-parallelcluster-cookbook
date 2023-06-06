require 'spec_helper'

describe 'aws-parallelcluster-environment::imds' do
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

        it 'does not create imds directory' do
          is_expected.to_not create_directory("#{node['cluster']['scripts_dir']}/imds")
        end
      end

      context "when slurm scheduler and head node" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['node_type'] = 'HeadNode'
            node.override['cluster']['scheduler'] = 'slurm'
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it 'creates the imds directory' do
          is_expected.to create_directory("#{node['cluster']['scripts_dir']}/imds").with(
            owner: 'root',
            group: 'root',
            mode:  '0744'
          )
        end

        it 'creates imds-access.sh script' do
          is_expected.to create_cookbook_file("#{node['cluster']['scripts_dir']}/imds/imds-access.sh").with(
            source: 'imds/imds-access.sh',
            owner: "root",
            group: "root",
            mode: "0744"
          )
        end

        it 'creates etc_dir directory' do
          is_expected.to create_directory("#{node['cluster']['etc_dir']}")
        end

        it "saves iptables rules" do
          is_expected.to run_execute("Save iptables rules").with(command: /iptables-save/)
        end

        it "saves ip6tables rules" do
          is_expected.to run_execute("Save ip6tables rules").with(command: /ip6tables-save/)
        end

        it 'creates iptables init.d file' do
          is_expected.to create_template("/etc/init.d/parallelcluster-iptables")
            .with(source: 'imds/parallelcluster-iptables.erb')
        end

        it 'starts parallelcluster-iptables service' do
          is_expected.to enable_service('parallelcluster-iptables').with_action(%i(enable start))
        end
      end

      context "when slurm scheduler and head node and imds_secured enabled" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['node_type'] = 'HeadNode'
            node.override['cluster']['scheduler'] = 'slurm'
            node.override['cluster']['head_node_imds_secured'] = 'true'
            node.override['cluster']['cluster_user'] = 'ec2-user'
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it "enables lockdown" do
          is_expected.to run_execute("IMDS lockdown enable")
            .with(command: "bash /opt/parallelcluster/scripts/imds/imds-access.sh --flush && bash /opt/parallelcluster/scripts/imds/imds-access.sh --allow root,#{node['cluster']['cluster_admin_user']},ec2-user")
        end
      end

      context "when slurm scheduler and head node and imds_secured disabled" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['node_type'] = 'HeadNode'
            node.override['cluster']['scheduler'] = 'slurm'
            node.override['cluster']['head_node_imds_secured'] = 'false'
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it "disables lockdown" do
          is_expected.to run_execute("IMDS lockdown disable")
            .with(command: "bash /opt/parallelcluster/scripts/imds/imds-access.sh --flush")
        end
      end

      context "when slurm scheduler and compute fleet" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['node_type'] = 'ComputeFleet'
            node.override['cluster']['scheduler'] = 'slurm'
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it 'does not create imds directory' do
          is_expected.to_not create_directory("#{node['cluster']['scripts_dir']}/imds")
        end
      end
    end
  end
end
