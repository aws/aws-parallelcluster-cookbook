require 'spec_helper'

describe 'aws-parallelcluster-slurm::update_head_node' do
  for_all_oses do |platform, version|
    cookbook_venv_path = "MOCK_COOKBOOK_VENV_PATH"
    cluster_name = "MOCK_CLUSTER_NAME"
    region = "MOCK_REGION"
    cluster_config_version = "MOCK_CLUSTER_CONFIG_VERSION"
    scripts_dir = "/MOCK_SCRIPTS_DIR"

    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = runner(platform: platform, version: version) do |node|
          allow_any_instance_of(Object).to receive(:are_mount_or_unmount_required?).and_return(false)
          allow_any_instance_of(Object).to receive(:dig).and_return(true)
          allow_any_instance_of(Object).to receive(:cookbook_virtualenv_path).and_return(cookbook_venv_path)
          RSpec::Mocks.configuration.allow_message_expectations_on_nil = true

          node.override['cluster']['stack_name'] = cluster_name
          node.override['cluster']['region'] = region
          node.override['cluster']['cluster_config_version'] = cluster_config_version
          node.override['cluster']['scripts_dir'] = scripts_dir
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
    end
  end
end
