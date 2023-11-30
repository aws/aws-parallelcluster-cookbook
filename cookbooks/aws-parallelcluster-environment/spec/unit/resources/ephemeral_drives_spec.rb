require 'spec_helper'

class ConvergeEphemeralDrives
  def self.setup(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-environment') do
      ephemeral_drives 'setup' do
        action :setup
      end
    end
  end
end

describe 'ephemeral_drives:setup' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:network_target) { %(redhat rocky).include?(platform) ? 'network-online.target' : 'network.target' }
      cached(:chef_run) do
        runner = runner(platform: platform, version: version, step_into: ['ephemeral_drives'])
        ConvergeEphemeralDrives.setup(runner)
      end

      it 'sets up ephemeral drives' do
        is_expected.to setup_ephemeral_drives('setup')
      end

      it 'installs Logical Volume Manager 2 utilities' do
        is_expected.to install_package('install Logical Volume Manager 2 utilities').with(
          package_name: 'lvm2',
          retries: 3,
          retry_delay: 5
        )
      end

      it 'creates file setup-ephemeral-drives.sh' do
        is_expected.to create_cookbook_file('setup-ephemeral-drives.sh').with(
          source: 'setup-ephemeral-drives.sh',
          path: '/usr/local/sbin/setup-ephemeral-drives.sh',
          owner: 'root',
          group: 'root',
          mode: '0744'
        )
      end

      it 'creates file setup-ephemeral.service' do
        is_expected.to create_template('setup-ephemeral.service').with(
          source:  'setup-ephemeral.service.erb',
          path:  '/etc/systemd/system/setup-ephemeral.service',
          owner:  'root',
          group:  'root',
          mode:  '0644',
          variables: { network_target: network_target }
        )
      end
    end
  end
end
