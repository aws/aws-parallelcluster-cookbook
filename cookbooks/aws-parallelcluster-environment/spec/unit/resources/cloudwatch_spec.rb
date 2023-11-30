require 'spec_helper'

class ConvergeCloudWatch
  def self.setup(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-environment') do
      cloudwatch 'setup' do
        action :setup
      end
    end
  end

  def self.configure(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-environment') do
      cloudwatch 'configure' do
        action :configure
      end
    end
  end
end

describe 'cloudwatch:setup' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:aws_region) { "aws_region" }
      cached(:aws_domain) { "aws_domain" }
      cached(:sources_dir) { "sources_dir" }
      cached(:public_key_local_path) { "#{sources_dir}/amazon-cloudwatch-agent.gpg" }
      cached(:s3_domain) { "https://s3.#{aws_region}.#{aws_domain}" }
      cached(:package_url_prefix) { "#{s3_domain}/amazoncloudwatch-agent-#{aws_region}" }
      cached(:package_extension) { platform == 'ubuntu' ? 'deb' : 'rpm' }
      cached(:signature_url) { "#{package_url}.sig" }
      cached(:package_path) { "#{sources_dir}/amazon-cloudwatch-agent.#{package_extension}" }
      cached(:signature_path) { "#{package_path}.sig" }

      context "when not on arm" do
        cached(:platform_url_component) do
          case platform
          when 'amazon'
            'amazon_linux'
          when 'rocky'
            'redhat'
          else
            platform
          end
        end
        cached(:package_url) { "#{package_url_prefix}/#{platform_url_component}/amd64/latest/amazon-cloudwatch-agent.#{package_extension}" }
        cached(:chef_run) do
          runner = runner(platform: platform, version: version, step_into: ['cloudwatch']) do |node|
            node.override['cluster']['sources_dir'] = sources_dir
            node.override['cluster']['region'] = aws_region
            node.override['cluster']['aws_domain'] = aws_domain
          end
          allow_any_instance_of(Object).to receive(:arm_instance?).and_return(false)
          ConvergeCloudWatch.setup(runner)
        end

        it 'sets up cloudwatch' do
          is_expected.to setup_cloudwatch('setup')
        end

        it 'creates source dir' do
          is_expected.to create_directory("sources_dir").with_recursive(true)
        end

        it 'downloads cloudwatch public key' do
          is_expected.to create_if_missing_remote_file(public_key_local_path).with(
            source: 'https://s3.amazonaws.com/amazoncloudwatch-agent/assets/amazon-cloudwatch-agent.gpg',
            retries: 3,
            retry_delay: 5
          )
        end

        it 'downloads cloudwatch package' do
          is_expected.to create_if_missing_remote_file(package_path).with(
            source: package_url,
            retries: 3,
            retry_delay: 5
          )
        end

        it 'downloads package signature' do
          is_expected.to create_if_missing_remote_file(signature_path).with(
            source: signature_url,
            retries: 3,
            retry_delay: 5
          )
        end

        it 'imports cloudwatch agent public key to the keyring' do
          is_expected.to run_execute('import-cloudwatch-agent-key').with_command("gpg --import #{public_key_local_path}")
        end

        it 'verifies cloudwatch agent public key fingerprint' do
          is_expected.to run_execute('verify-cloudwatch-agent-public-key-fingerprint')
            .with_command('gpg --list-keys --fingerprint "Amazon CloudWatch Agent" | grep "9376 16F3 450B 7D80 6CBD  9725 D581 6730 3B78 9C72"')
        end

        it 'verifies cloudwatch agent package signature' do
          is_expected.to run_execute('verify-cloudwatch-agent-rpm-signature')
            .with_command("gpg --verify #{signature_path} #{package_path}")
        end

        it('installs cloudwatch package') do
          if platform == 'ubuntu'
            is_expected.to install_dpkg_package(package_path).with_source(package_path)
          else
            is_expected.to install_package(package_path)
          end
        end
      end

      context "when on arm" do
        cached(:platform_url_component) do
          case platform
          when 'amazon'
            'amazon_linux'
          when 'centos', 'rocky'
            'redhat'
          else
            platform
          end
        end
        cached(:package_url) { "#{package_url_prefix}/#{platform_url_component}/arm64/latest/amazon-cloudwatch-agent.#{package_extension}" }
        cached(:chef_run) do
          runner = runner(platform: platform, version: version, step_into: ['cloudwatch']) do |node|
            node.override['cluster']['sources_dir'] = sources_dir
            node.override['cluster']['region'] = aws_region
            node.override['cluster']['aws_domain'] = aws_domain
          end
          allow_any_instance_of(Object).to receive(:arm_instance?).and_return(true)
          ConvergeCloudWatch.setup(runner)
        end

        it 'downloads cloudwatch package' do
          is_expected.to create_if_missing_remote_file(package_path).with(
            source: package_url,
            retries: 3,
            retry_delay: 5
          )
        end
      end
    end
  end
end

describe 'cloudwatch:configure' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:config_script_path) { '/usr/local/bin/write_cloudwatch_agent_json.py' }
      cached(:config_schema_path) { '/usr/local/etc/cloudwatch_agent_config_schema.json' }
      cached(:config_data_path) { '/usr/local/etc/cloudwatch_agent_config.json' }
      cached(:validator_script_path) { '/usr/local/bin/cloudwatch_agent_config_util.py' }
      cached(:cookbook_venv_path) { 'cookbook/virtual/env/path' }
      cached(:log_group_name) { 'test_log_group_name' }
      cached(:scheduler) { 'test_scheduler' }
      cached(:node_type) { 'test_node_type' }
      cached(:cluster_config_path) { 'cluster_test_config_path' }

      context "when not yet configured and cloudwatch logging enabled" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version, step_into: ['cloudwatch']) do |node|
            node.override['cluster']['log_group_name'] = log_group_name
            node.override['cluster']['scheduler'] = scheduler
            node.override['cluster']['node_type'] = node_type
            node.override['cluster']['cluster_config_path'] = cluster_config_path
            node.override['cluster']['cw_logging_enabled'] = 'true'
          end
          allow_any_instance_of(Object).to receive(:cookbook_virtualenv_path).and_return(cookbook_venv_path)
          stub_command("/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status | grep status | grep running").and_return(false)
          allow(File).to receive(:exist?).with('/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json').and_return(false)
          ConvergeCloudWatch.configure(runner)
        end

        it 'configures cloudwatch' do
          is_expected.to configure_cloudwatch('configure')
        end

        it 'creates write_cloudwatch_agent_json.py' do
          is_expected.to create_if_missing_cookbook_file('/usr/local/bin/write_cloudwatch_agent_json.py').with(
            source: 'cloudwatch/write_cloudwatch_agent_json.py',
            path: '/usr/local/bin/write_cloudwatch_agent_json.py',
            user: 'root',
            group: 'root',
            mode: '0755'
          )
        end

        it 'creates cloudwatch_agent_config.json' do
          is_expected.to create_if_missing_cookbook_file('cloudwatch_agent_config.json').with(
            source: 'cloudwatch/cloudwatch_agent_config.json',
            path: config_data_path,
            user: 'root',
            group: 'root',
            mode: '0644'
          )
        end

        it 'creates cloudwatch_agent_config_schema.json' do
          is_expected.to create_if_missing_cookbook_file('cloudwatch_agent_config_schema.json').with(
            source: 'cloudwatch/cloudwatch_agent_config_schema.json',
            path: config_schema_path,
            user: 'root',
            group: 'root',
            mode: '0644'
          )
        end

        it 'creates cloudwatch_agent_config_util.py' do
          is_expected.to create_if_missing_cookbook_file('cloudwatch_agent_config_util.py').with(
            source: 'cloudwatch/cloudwatch_agent_config_util.py',
            path: validator_script_path,
            user: 'root',
            group: 'root',
            mode: '0644'
          )
        end

        it 'validates cloudwatch' do
          is_expected.to run_execute('cloudwatch-config-validation').with(
            user: 'root',
            timeout: 300,
            environment: {
              'CW_LOGS_CONFIGS_SCHEMA_PATH' => config_schema_path,
              'CW_LOGS_CONFIGS_PATH' => config_data_path,
            },
            command: "#{cookbook_venv_path}/bin/python #{validator_script_path}"
          )
        end

        it 'creates cloudwatch config' do
          is_expected.to run_execute('cloudwatch-config-creation').with(
            user: 'root',
            timeout: 300,
            environment: {
              'LOG_GROUP_NAME' => log_group_name,
              'SCHEDULER' => scheduler,
              'NODE_ROLE' => node_type,
              'CONFIG_DATA_PATH' => config_data_path,
            }
          )
        end

        it 'starts cloudwatch agent' do
          is_expected.to run_execute("cloudwatch-agent-start").with(
            user: 'root',
            timeout: 300,
            command: "/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s"
          )
        end
      end

      context "when cloudwatch config already exists" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version, step_into: ['cloudwatch']) do |node|
            node.override['cluster']['log_group_name'] = log_group_name
            node.override['cluster']['scheduler'] = scheduler
            node.override['cluster']['node_type'] = node_type
            node.override['cluster']['cluster_config_path'] = cluster_config_path
          end
          allow(File).to receive(:exist?).with('/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json').and_return(true)
          stub_command("/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status | grep status | grep running").and_return(false)
          ConvergeCloudWatch.configure(runner)
        end

        it 'does not owerwrite cloudwatch config' do
          is_expected.not_to run_execute('cloudwatch-config-creation')
        end
      end

      context "cloudwatch logging disabled" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version, step_into: ['cloudwatch']) do |node|
            node.override['cluster']['log_group_name'] = log_group_name
            node.override['cluster']['scheduler'] = scheduler
            node.override['cluster']['node_type'] = node_type
            node.override['cluster']['cluster_config_path'] = cluster_config_path
            node.override['cluster']['cw_logging_enabled'] = 'false'
          end
          stub_command("/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status | grep status | grep running").and_return(false)
          ConvergeCloudWatch.configure(runner)
        end

        it 'does not start cloudwatch' do
          is_expected.not_to run_execute("cloudwatch-agent-start")
        end
      end

      context "cloudwatch agent already running" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version, step_into: ['cloudwatch']) do |node|
            node.override['cluster']['log_group_name'] = log_group_name
            node.override['cluster']['scheduler'] = scheduler
            node.override['cluster']['node_type'] = node_type
            node.override['cluster']['cluster_config_path'] = cluster_config_path
            node.override['cluster']['cw_logging_enabled'] = 'true'
          end
          stub_command('/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status | grep status | grep running').and_return(true)
          ConvergeCloudWatch.configure(runner)
        end

        it 'does not start cloudwatch' do
          is_expected.not_to run_execute("cloudwatch-agent-start")
        end
      end
    end
  end
end
