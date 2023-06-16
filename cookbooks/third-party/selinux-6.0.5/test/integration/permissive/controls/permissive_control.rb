include_controls 'common'

control 'permissive' do
  title 'Verify that SELinux is permissive'

  describe file('/etc/selinux/config') do
    it { should exist }
    it { should be_file }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0644' }
    its('content') { should include 'SELINUX=permissive' }
  end

  describe selinux do
    it { should be_installed }
    it { should_not be_disabled }
    it { should_not be_enforcing }
    it { should be_permissive }
    its('policy') { should eq os.family.eql?('debian') ? 'default' : 'targeted' }
  end
end
