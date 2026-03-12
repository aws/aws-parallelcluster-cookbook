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
    time_now = "2024-01-16T15:30:45.000+00:00"

    context "on #{platform}#{version}" do
      [true, false].each do |are_mount_or_unmount_required|
        context "when mount/unmount is #{'not ' unless are_mount_or_unmount_required}required" do
          cached(:chef_run) do
            runner = runner(platform: platform, version: version) do |node|
              allow_any_instance_of(Object).to receive(:are_mount_or_unmount_required?).and_return(are_mount_or_unmount_required)
              allow_any_instance_of(Object).to receive(:dig).and_return(true)
              allow_any_instance_of(Object).to receive(:cookbook_virtualenv_path).and_return(cookbook_venv_path)
              allow_any_instance_of(Object).to receive(:cluster_readiness_check_on_update_enabled?).and_return(true)
              allow(Time).to receive(:now).and_return(Time.parse(time_now))
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
              " --region #{region}" \
              " --cutoff-time '#{time_now}'"
            is_expected.to run_execute("Check cluster readiness").with(
              command: expected_command,
              timeout: 30,
              retries: 10,
              retry_delay: 90
            )
          end

          it 'does not cleanup DNA files after update' do
            is_expected.not_to run_execute("Cleanup dna.json and extra.json from #{chef_run.node['cluster']['shared_dir']}/dna")
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
