control 'tag:install_ec2_udev_rules_write_common_udev_configuration_files' do
  title "write udev configuration files for all OSes"

  describe file('/etc/udev/rules.d/52-ec2-volid.rules') do
    it { should exist }
    its('content') { should match '/opt/parallelcluster/pyenv' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0644' }
  end

  paths = %w(/usr/local/sbin/parallelcluster-ebsnvme-id /sbin/ec2_dev_2_volid.py)
  paths.each do |path|
    describe file(path) do
      it { should exist }
      its('content') { should_not be_empty }
      its('owner') { should eq 'root' }
      its('group') { should eq 'root' }
      its('mode') { should cmp '0744' }
    end
  end

  describe file('/usr/local/sbin/manageVolume.py') do
    it { should exist }
    its('content') { should_not be_empty }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0755' }
  end
end

control 'tag:install_tag:config_ec2_udev_rules_ec2blkdev_service_installation' do
  title "Installation of the ec2blkdev service"

  only_if { !os_properties.on_docker? }
end
