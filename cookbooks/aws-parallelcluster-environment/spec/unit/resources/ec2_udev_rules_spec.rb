require 'spec_helper'

class ConvergeEc2UdevRules
  def self.setup(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-environment') do
      ec2_udev_rules 'setup' do
        action :setup
      end
    end
  end
end

describe 'ec2_udev_rules:setup' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = runner(platform: platform, version: version, step_into: ['ec2_udev_rules'])
        ConvergeEc2UdevRules.setup(runner)
      end

      it 'sets up ec2 udev rules' do
        is_expected.to setup_ec2_udev_rules('setup')
      end

      it 'creates common udev files' do
        is_expected.to create_directory('/etc/udev/rules.d').with(recursive: true)

        is_expected.to create_template('ec2-volid.rules')
          .with(source: 'ec2_udev_rules/ec2-volid.rules.erb')
          .with(path: '/etc/udev/rules.d/52-ec2-volid.rules')
          .with(user: 'root')
          .with(group: 'root')
          .with(mode: '0644')

        is_expected.to create_template('parallelcluster-ebsnvme-id')
          .with(source: 'ec2_udev_rules/parallelcluster-ebsnvme-id.erb')
          .with(path: '/usr/local/sbin/parallelcluster-ebsnvme-id')
          .with(user: 'root')
          .with(group: 'root')
          .with(mode: '0744')

        is_expected.to create_cookbook_file('ec2_dev_2_volid.py')
          .with(source: 'ec2_udev_rules/ec2_dev_2_volid.py')
          .with(path: '/sbin/ec2_dev_2_volid.py')
          .with(user: 'root')
          .with(group: 'root')
          .with(mode: '0744')

        is_expected.to create_cookbook_file('ec2blkdev-init')
          .with(source: 'ec2_udev_rules/ec2blkdev-init')
          .with(path: '/etc/init.d/ec2blkdev')
          .with(user: 'root')
          .with(group: 'root')
          .with(mode: '0744')

        is_expected.to create_cookbook_file('manageVolume.py')
          .with(source: 'ec2_udev_rules/manageVolume.py')
          .with(path: '/usr/local/sbin/manageVolume.py')
          .with(user: 'root')
          .with(group: 'root')
          .with(mode: '0755')
      end

      if platform == 'ubuntu'
        it 'sets udev autoreload' do
          is_expected.to nothing_execute('udev-daemon-reload')
            .with(command: 'udevadm control --reload')

          is_expected.to create_directory('/etc/systemd/system/systemd-udevd.service.d')

          is_expected.to create_cookbook_file('udev-override.conf')
            .with(source: 'ec2_udev_rules/udev-override.conf')
            .with(path: '/etc/systemd/system/systemd-udevd.service.d/override.conf')
            .with(user: 'root')
            .with(group: 'root')
            .with(mode: '0644')

          expect(chef_run.cookbook_file('udev-override.conf')).to notify('execute[udev-daemon-reload]').to(:run).immediately
        end
      end

      it 'enables and starts ec2blk service' do
        is_expected.to enable_service('ec2blkdev')
          .with(supports: { restart: true })
        is_expected.to start_service('ec2blkdev')
          .with(supports: { restart: true })
      end
    end
  end
end
