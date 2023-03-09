require 'spec_helper'

class ConvergeNetworkService
  def self.restart(chef_run)
    chef_run.converge_dsl do
      network_service 'restart' do
        action :restart
      end
    end
  end

  def self.reload(chef_run)
    chef_run.converge_dsl do
      network_service 'reload' do
        action :reload
      end
    end
  end
end

describe 'network_service:restart' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = ChefSpec::Runner.new(
          platform: platform, version: version,
          step_into: ['network_service']
        )
        ConvergeNetworkService.restart(runner)
      end
      cached(:node) { chef_run.node }
      cached(:network_service_name) do
        {
          'amazon' => 'network',
          'centos' => 'network',
          'redhat' => 'NetworkManager',
          'ubuntu' => 'systemd-resolved',
        }[platform]
      end

      it "restarts network service" do
        is_expected.to write_log("Restarting '#{network_service_name}' service, platform #{platform} '#{node['platform_version']}'")

        is_expected.to restart_service(network_service_name)
          .with(ignore_failure: true)
      end
    end
  end
end

describe 'network_service:reload' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = ChefSpec::Runner.new(
          platform: platform, version: version,
          step_into: ['network_service']
        )
        ConvergeNetworkService.reload(runner)
      end
      cached(:network_service_name) do
        {
          'amazon' => 'network',
          'centos' => 'network',
          'redhat' => 'NetworkManager',
          'ubuntu' => 'systemd-resolved',
        }[platform]
      end

      if platform == 'ubuntu'
        it "applies network configuration" do
          is_expected.to run_execute("apply network configuration")
            .with(command: "netplan apply")
            .with(timeout: 60)
        end

        it "doesn't restart network service" do
          is_expected.not_to restart_service(network_service_name)
        end
      else
        it "restarts network service" do
          is_expected.to restart_service(network_service_name)
        end
      end
    end
  end
end
