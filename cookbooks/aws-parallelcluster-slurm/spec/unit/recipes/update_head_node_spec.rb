require 'spec_helper'

describe 'aws-parallelcluster-slurm::update_head_node' do
  for_all_oses do |platform, version|
    cookbook_venv_path = "MOCK_COOKBOOK_VENV_PATH"
    cluster_name = "MOCK_CLUSTER_NAME"
    region = "MOCK_REGION"
    cluster_config_version = "MOCK_CLUSTER_CONFIG_VERSION"
    scripts_dir = "/MOCK_SCRIPTS_DIR"
    slurm_install_dir = "/MOCK_SLURM_INSTALL_DIR"
    reconfigure_timeout = 600

    context "on #{platform}#{version}" do
      [true, false].each do |are_mount_or_unmount_required|
        context "when mount/unmount is #{'not ' unless are_mount_or_unmount_required}required" do
          cached(:chef_run) do
            runner = runner(platform: platform, version: version) do |node|
              allow_any_instance_of(Object).to receive(:are_mount_or_unmount_required?).and_return(are_mount_or_unmount_required)
              allow_any_instance_of(Object).to receive(:dig).and_return(true)
              allow_any_instance_of(Object).to receive(:cookbook_virtualenv_path).and_return(cookbook_venv_path)
              allow_any_instance_of(Object).to receive(:cluster_readiness_check_on_update_enabled?).and_return(true)
              RSpec::Mocks.configuration.allow_message_expectations_on_nil = true

              node.override['cluster']['stack_name'] = cluster_name
              node.override['cluster']['region'] = region
              node.override['cluster']['cluster_config_version'] = cluster_config_version
              node.override['cluster']['scripts_dir'] = scripts_dir
              node.override['cluster']['slurm']['install_dir'] = slurm_install_dir
              node.override['cluster']['slurm']['reconfigure_timeout'] = reconfigure_timeout
            end
            runner.converge(described_recipe)
          end

          it 'creates the template cfnconfig' do
            is_expected.to create_template('/etc/parallelcluster/cfnconfig').with(
              source: 'init/cfnconfig.erb',
              cookbook: 'aws-parallelcluster-environment',
              mode:  '0644'
            )
          end

          it 'writes the config version to shared update file' do
            is_expected.to create_file(chef_run.node['cluster']['update']['trigger_file']).with(
              content: cluster_config_version,
              owner: 'root',
              group: 'root',
              mode: '0644'
            )
          end

          if are_mount_or_unmount_required
            it 'updates the shared storage' do
              is_expected.to run_ruby_block("update_shared_storages")
            end
          else
            it 'does not update the shared storage' do
              is_expected.not_to run_ruby_block("update_shared_storages")
            end
          end

          it 'checks cluster readiness' do
            expected_command = "#{cookbook_venv_path}/bin/python #{scripts_dir}/head_node_checks/check_cluster_ready.py" \
              " --cluster-name #{cluster_name}" \
              " --table-name parallelcluster-#{cluster_name}" \
              " --config-version #{cluster_config_version}" \
              " --region #{region}"
            is_expected.to run_execute("Check cluster readiness").with(
              command: expected_command,
              timeout: 30,
              retries: 10,
              retry_delay: 90
            )
          end

          it 'starts clustermgtd unconditionally' do
            is_expected.to run_execute('start clustermgtd').with(
              command: "#{cookbook_venv_path}/bin/supervisorctl start clustermgtd"
            )
          end

          it 'runs scontrol reconfigure with timeout from attribute' do
            is_expected.to run_execute('reload config for running nodes').with(
              command: "#{slurm_install_dir}/bin/scontrol reconfigure",
              timeout: reconfigure_timeout
            )
          end

          it 'executes resources in the correct order' do
            # NOTE: The most important aspect in the sequence is that clustermgtd is stopped while executing:
            #   1. update_munge_key
            #   2. restart of slurmctld
            #   3. scontrol reconfigure
            resource_names = chef_run.resource_collection.map(&:name)

            expected_sequence = [
              'stop clustermgtd',
              chef_run.node['cluster']['update']['trigger_file'],
              'update_shared_storages',
              'replace slurm queue nodes',
              'Update or Cleanup Slurm Topology',
              'generate_pcluster_slurm_configs',
              'generate_pcluster_custom_slurm_settings_include_files',
              'Override Custom Slurm Settings with remote file',
              'generate_pcluster_fleet_config',
              'update node replacement timeout',
              "#{scripts_dir}/slurm/check_login_nodes_stopped.sh",
              "#{scripts_dir}/slurm/update_munge_key.sh",
              'update Slurm database password',
              'update_munge_key',
              'Update Slurm Accounting',
              'slurmctld',
              '5',
              'check slurmctld status',
              'reload config for running nodes',
              '15',
              'start clustermgtd',
              'Check cluster readiness',
              '/etc/parallelcluster/cfnconfig',
              'Cleanup',
            ]

            expect(resource_names).to eq(expected_sequence)
          end
        end
      end

      context 'when cluster readiness check is disabled' do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            allow_any_instance_of(Object).to receive(:are_mount_or_unmount_required?).and_return(false)
            allow_any_instance_of(Object).to receive(:dig).and_return(true)
            allow_any_instance_of(Object).to receive(:cookbook_virtualenv_path).and_return(cookbook_venv_path)
            allow_any_instance_of(Object).to receive(:cluster_readiness_check_on_update_enabled?).and_return(false)
            RSpec::Mocks.configuration.allow_message_expectations_on_nil = true

            node.override['cluster']['stack_name'] = cluster_name
            node.override['cluster']['region'] = region
            node.override['cluster']['cluster_config_version'] = cluster_config_version
            node.override['cluster']['scripts_dir'] = scripts_dir
          end
          runner.converge(described_recipe)
        end
        it 'does not check cluster readiness' do
          is_expected.not_to run_execute("Check cluster readiness")
        end
      end
    end
  end
end
