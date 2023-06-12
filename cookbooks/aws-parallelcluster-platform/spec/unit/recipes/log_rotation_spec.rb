require 'spec_helper'

describe 'aws-parallelcluster-platform::log_rotation' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:log_rotation_path) { "/etc/logrotate.d/parallelcluster_log_rotation" }

      context "in the head node when log_rotation enabled and dcv enabled and slurm" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['node_type'] = "HeadNode"
            node.override['cluster']['log_rotation_enabled'] = 'true'
            node.override['cluster']['dcv_enabled'] = "head_node"
            node.override['cluster']["directory_service"]["generate_ssh_keys_for_users"] = 'true'
            node.override['cluster']["scheduler"] = 'slurm'
            allow_any_instance_of(Object).to receive(:dcv_installed?).and_return(true)
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it 'creates the template with the correct attributes' do
          is_expected.to create_template(log_rotation_path).with(
            source: 'log_rotation/parallelcluster_log_rotation.erb',
            mode:  '0644',
            variables: { dcv_configured: true }
          )
        end

        it 'has the correct content' do
          is_expected.to render_file(log_rotation_path)
            .with_content("/var/log/cloud-init.log")
            .with_content("/var/log/cfn-init.log")
            .with_content("/var/log/dcv/server.log")
            .with_content("/var/log/parallelcluster/pam_ssh_key_generator.log")

          is_expected.to_not render_file(log_rotation_path)
            .with_content("/var/log/cloud-init-output.log")
            .with_content("/var/log/parallelcluster/computemgtd")
        end
      end

      context "in the compute node when log_rotation enabled, dcv enabled but not installed" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['node_type'] = "ComputeFleet"
            node.override['cluster']['log_rotation_enabled'] = 'true'
            node.override['cluster']['dcv_enabled'] = "head_node"
            allow_any_instance_of(Object).to receive(:dcv_installed?).and_return(false)
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it 'has the correct content' do
          is_expected.to render_file(log_rotation_path)
            .with_content("/var/log/cloud-init.log")
            .with_content("/var/log/cloud-init-output.log")
            .with_content("/var/log/parallelcluster/computemgtd")

          is_expected.to_not render_file(log_rotation_path)
            .with_content("/var/log/cfn-init.log")
            .with_content("/var/log/dcv/server.log")
        end
      end

      context "in the head node when log_rotation enabled and dcv not enabled and awsbatch" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['node_type'] = "HeadNode"
            node.override['cluster']['log_rotation_enabled'] = 'true'
            node.override['cluster']['dcv_enabled'] = "NONE"
            node.override['cluster']["scheduler"] = 'awsbatch'
            node.override['cluster']["directory_service"]["generate_ssh_keys_for_users"] = nil
            allow_any_instance_of(Object).to receive(:dcv_installed?).and_return(true)
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it 'has the correct content' do
          is_expected.to render_file(log_rotation_path)
            .with_content("/var/log/cloud-init.log")

          is_expected.to_not render_file(log_rotation_path)
            .with_content("/var/log/dcv/server.log")
            .with_content("/var/log/cfn-init.log")
            .with_content("/var/log/parallelcluster/computemgtd")
            .with_content("/var/log/parallelcluster/pam_ssh_key_generator.log")
        end
      end

      context "when log_rotation disabled" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['log_rotation_enabled'] = 'false'
          end
          runner.converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it 'has the correct content' do
          is_expected.to_not render_file(log_rotation_path)
        end
      end
    end
  end
end
