case os.family
when 'debian', 'ubuntu'
  describe file('/etc/iptables/rules.v4') do
    it { should exist }
  end
  describe service('netfilter-persistent') do
    it { should be_installed }
    it { should be_running }
    it { should be_enabled }
  end
when 'redhat', 'fedora'
  describe file('/etc/sysconfig/iptables-config') do
    its(:content) { should match /IPTABLES_STATUS_VERBOSE="no"/ }
  end
  describe service('iptables') do
    it { should be_installed }
    it { should be_running }
    it { should be_enabled }
  end
end
