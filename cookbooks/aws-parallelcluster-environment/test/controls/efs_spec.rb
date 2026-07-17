# Use the name matching the resource type
control 'tag:install_efs_utils_installed' do
  title 'Verify that efs_utils is installed'

  only_if { !os_properties.redhat_on_docker? && !node['cluster']['efs']['skip_install'] }

  # The commercial repo installs the newest release within the tracked major, so
  # assert the major line rather than the exact efs.version pin.
  efs_major = node['cluster']['efs']['version'].split('.').first

  describe package('amazon-efs-utils') do
    it { should be_installed }
    its('version') { should start_with(efs_major) }
  end

  # mount.efs reports the installed efs-utils version, e.g.
  # "/usr/sbin/mount.efs Version: 3.1.3".
  describe command('mount.efs --version') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match(/Version:\s*#{efs_major}\./) }
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
