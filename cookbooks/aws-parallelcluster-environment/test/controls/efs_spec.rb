# Use the name matching the resource type
control 'tag:install_efs_utils_installed' do
  title 'Verify that efs_utils is installed'

  only_if { !os_properties.redhat_on_docker? }

  describe file("#{node['cluster']['sources_dir']}/efs-utils-1.34.1.tar.gz") do
    it { should exist }
    its('sha256sum') { should eq '69d0d8effca3b58ccaf4b814960ec1d16263807e508b908975c2627988c7eb6c' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0644' }
  end unless os_properties.alinux?

  describe package('amazon-efs-utils') do
    it { should be_installed }
  end

  describe file("/etc/amazon/efs/efs-utils.conf") do
    its('content') do
      should match('poll_interval_sec = 10')
    end
  end
end

control 'efs_mounted' do
  title 'Verify that an existing efs filesystem can be mounted'

  only_if { !os_properties.on_docker? }
  describe mount('/shared_dir') do
    it { should be_mounted }
    its('device') { should eq 'fs-03ad31942a4205839.efs.us-west-2.amazonaws.com:/' }
    its('type') { should eq 'nfs4' }
    its('options') { should include '_netdev' }
  end
end

control 'efs_unmounted' do
  title 'Verify that an existing efs filesystem can be unmounted'

  only_if { !os_properties.on_docker? }

  describe mount('/shared_dir') do
    it { should_not be_mounted }
  end
end
