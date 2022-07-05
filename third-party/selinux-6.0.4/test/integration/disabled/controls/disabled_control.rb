include_controls 'common'

control 'disabled' do
  title 'Verify SELinux is disabled'

  describe file('/etc/selinux/config') do
    it { should exist }
    it { should be_file }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0644' }
    its('content') { should include 'SELINUX=disabled' }
  end

  describe selinux do
    it { should be_installed }
    it { should be_disabled }
    it { should_not be_enforcing }
    it { should_not be_permissive }
  end
end
