require 'spec_helper'

describe 'aws-parallelcluster-platform::log_rotation' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:log_rotation_path) { "/etc/logrotate.d/" }

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

        expected_config_files = %w(
          parallelcluster_cloud_init_log_rotation
          parallelcluster_supervisord_log_rotation
          parallelcluster_bootstrap_error_msg_log_rotation
          parallelcluster_cfn_init_log_rotation
          parallelcluster_chef_client_log_rotation
          parallelcluster_dcv_log_rotation
          parallelcluster_pam_ssh_key_generator_log_rotation
          parallelcluster_clustermgtd_log_rotation
          parallelcluster_clusterstatusmgtd_log_rotation
          parallelcluster_slurm_fleet_status_manager_log_rotation
          parallelcluster_slurm_resume_log_rotation
          parallelcluster_slurm_suspend_log_rotation
          parallelcluster_slurmctld_log_rotation
          parallelcluster_slurmdbd_log_rotation
          parallelcluster_compute_console_output_log_rotation
          parallelcluster_clustermgtd_events_log_rotation
          parallelcluster_slurm_resume_events_log_rotation
        )
        unexpected_config_files = %w(
          parallelcluster_cloud_init_output_log_rotation
          parallelcluster_computemgtd_log_rotation
          parallelcluster_slurmd_log_rotation
        )

        it 'creates the correct logrotate config files' do
          expected_config_files.each do |config_file |
            output_file = log_rotation_path + config_file
            template_file = 'log_rotation/' + config_file + '.erb'
            is_expected.to create_template(output_file).with(
              source: template_file,
              mode:  '0644',
              )
          end
        end

        it 'does not create unexpected logrotate config files' do
          unexpected_config_files.each do |config_file |
            output_file = log_rotation_path + config_file
            is_expected.to_not create_template(output_file)
          end
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

        expected_config_files = %w(
          parallelcluster_cloud_init_log_rotation
          parallelcluster_supervisord_log_rotation
          parallelcluster_bootstrap_error_msg_log_rotation
          parallelcluster_cloud_init_output_log_rotation
          parallelcluster_computemgtd_log_rotation
          parallelcluster_slurmd_log_rotation
        )

        unexpected_config_files = %w(
          parallelcluster_cfn_init_log_rotation
          parallelcluster_chef_client_log_rotation
          parallelcluster_dcv_log_rotation
          parallelcluster_pam_ssh_key_generator_log_rotation
          parallelcluster_clustermgtd_log_rotation
          parallelcluster_clusterstatusmgtd_log_rotation
          parallelcluster_slurm_fleet_status_manager_log_rotation
          parallelcluster_slurm_resume_log_rotation
          parallelcluster_slurm_suspend_log_rotation
          parallelcluster_slurmctld_log_rotation
          parallelcluster_slurmdbd_log_rotation
          parallelcluster_compute_console_output_log_rotation
          parallelcluster_clustermgtd_events_log_rotation
          parallelcluster_slurm_resume_events_log_rotation
        )

        it 'creates the correct logrotate config files' do
          expected_config_files.each do |config_file |
            output_file = log_rotation_path + config_file
            template_file = 'log_rotation/' + config_file + '.erb'
            is_expected.to create_template(output_file).with(
              source: template_file,
              mode:  '0644',
              )
          end
        end

        it 'does not create unexpected logrotate config files' do
          unexpected_config_files.each do |config_file |
            output_file = log_rotation_path + config_file
            is_expected.to_not create_template(output_file)
          end
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

        expected_config_files = %w(
          parallelcluster_cloud_init_log_rotation
          parallelcluster_supervisord_log_rotation
          parallelcluster_bootstrap_error_msg_log_rotation
          parallelcluster_cfn_init_log_rotation
          parallelcluster_chef_client_log_rotation
        )
        unexpected_config_files = %w(
          parallelcluster_cloud_init_output_log_rotation
          parallelcluster_computemgtd_log_rotation
          parallelcluster_slurmd_log_rotation
          parallelcluster_pam_ssh_key_generator_log_rotation
          parallelcluster_dcv_log_rotation
          parallelcluster_clustermgtd_log_rotation
          parallelcluster_clusterstatusmgtd_log_rotation
          parallelcluster_slurm_fleet_status_manager_log_rotation
          parallelcluster_slurm_resume_log_rotation
          parallelcluster_slurm_suspend_log_rotation
          parallelcluster_slurmctld_log_rotation
          parallelcluster_slurmdbd_log_rotation
          parallelcluster_compute_console_output_log_rotation
          parallelcluster_clustermgtd_events_log_rotation
          parallelcluster_slurm_resume_events_log_rotation
        )

        it 'creates the correct logrotate config files' do
          expected_config_files.each do |config_file |
            output_file = log_rotation_path + config_file
            template_file = 'log_rotation/' + config_file + '.erb'
            is_expected.to create_template(output_file).with(
              source: template_file,
              mode:  '0644',
              )
          end
        end

        it 'does not create unexpected logrotate config files' do
          unexpected_config_files.each do |config_file |
            output_file = log_rotation_path + config_file
            is_expected.to_not create_template(output_file)
          end
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

        unexpected_config_files = %w(
          parallelcluster_cloud_init_log_rotation
          parallelcluster_supervisord_log_rotation
          parallelcluster_bootstrap_error_msg_log_rotation
          parallelcluster_cfn_init_log_rotation
          parallelcluster_chef_client_log_rotation
          parallelcluster_cloud_init_output_log_rotation
          parallelcluster_computemgtd_log_rotation
          parallelcluster_slurmd_log_rotation
          parallelcluster_pam_ssh_key_generator_log_rotation
          parallelcluster_dcv_log_rotation
          parallelcluster_clustermgtd_log_rotation
          parallelcluster_clusterstatusmgtd_log_rotation
          parallelcluster_slurm_fleet_status_manager_log_rotation
          parallelcluster_slurm_resume_log_rotation
          parallelcluster_slurm_suspend_log_rotation
          parallelcluster_slurmctld_log_rotation
          parallelcluster_slurmdbd_log_rotation
          parallelcluster_compute_console_output_log_rotation
          parallelcluster_clustermgtd_events_log_rotation
          parallelcluster_slurm_resume_events_log_rotation
        )

        it 'does not create unexpected logrotate config files' do
          unexpected_config_files.each do |config_file |
            output_file = log_rotation_path + config_file
            is_expected.to_not create_template(output_file)
          end
        end

      end

    end

  end

end
