require 'spec_helper'

for_all_oses do |platform, version|
  context "on #{platform}#{version}" do
    cached(:chrony_conf_path) { platform == 'ubuntu' ? '/etc/chrony/chrony.conf' : '/etc/chrony.conf' }
    cached(:chrony_service) { platform == 'ubuntu' ? 'chrony' : 'chronyd' }
    cached(:reload_command) { "systemctl force-reload #{chrony_service}" }

    describe 'aws-parallelcluster-platform::chrony setup' do
      cached(:chef_run) do
        ChefSpec::Runner.new(
          platform: platform, version: version, step_into: ['chrony']
        ).converge_dsl('aws-parallelcluster-platform') do
          chrony 'setup' do
            action :setup
          end
        end
      end

      it 'sets up chrony' do
        is_expected.to setup_chrony('setup')
      end

      it 'removes ntp packages' do
        is_expected.to remove_package(%w(ntp ntpdate ntp*))
      end

      it 'installs chrony' do
        is_expected.to install_package('chrony')
      end

      it 'adds configuration to chrony.conf' do
        is_expected.to edit_append_if_no_line('add configuration to chrony.conf').with(
          path: chrony_conf_path,
          line: "server 169.254.169.123 prefer iburst minpoll 4 maxpoll 4"
        )

        chef_run.append_if_no_line('add configuration to chrony.conf').tap do |appender|
          expect(appender).to notify("service[#{chrony_service}]").to(:stop).immediately
          expect(appender).to notify("service[#{chrony_service}]").to(:reload).delayed
        end
      end

      it 'waits for chrony service to be reloaded' do
        is_expected.to nothing_service(chrony_service)
          .with_reload_command(reload_command)
      end
    end

    describe 'aws-parallelcluster-platform::chrony enable' do
      cached(:chef_run) do
        ChefSpec::Runner.new(
          platform: platform, version: version, step_into: ['chrony']
        ).converge_dsl('aws-parallelcluster-platform') do
          chrony 'enable' do
            action :enable
          end
        end
      end

      it 'enables chrony' do
        is_expected.to enable_chrony('enable')
      end

      it 'enables and starts chrony service' do
        is_expected.to enable_service(chrony_service).with(
          supports: { restart: false },
          reload_command: reload_command,
          action: %i(enable start)
        )
      end
    end
  end
end
