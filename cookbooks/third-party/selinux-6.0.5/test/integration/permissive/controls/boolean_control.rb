control 'boolean' do
  title 'Verify SELinux booleans are set correctly'

  describe selinux.booleans.where(name: 'ssh_keysign') do
    it { should exist }
    its('states') { should include 'on' }
  end unless os.family.eql?('debian')

  describe selinux.booleans.where(name: 'httpd_enable_cgi') do
    it { should exist }
    its('states') { should include 'off' }
  end

  describe selinux.booleans.where(name: 'ssh_sysadm_login') do
    it { should exist }
    its('states') { should include 'on' }
  end

  describe selinux.booleans.where(name: 'squid_connect_any') do
    it { should exist }
    its('states') { should include 'off' }
  end
end
