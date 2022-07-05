include_controls 'common'

control 'enforcing' do
  title 'Verify that SELinux is enforcing'

  describe file('/etc/selinux/config') do
    it { should exist }
    it { should be_file }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0644' }
    its('content') { should include 'SELINUX=enforcing' }
  end

  describe selinux do
    it { should be_installed }
    it { should_not be_disabled }
    it { should be_enforcing }
    it { should_not be_permissive }
    if os.family.eql?('debian')
      its('policy') { should eq 'default' }
    else
      its('policy') { should eq 'targeted' }
    end
  end
end
