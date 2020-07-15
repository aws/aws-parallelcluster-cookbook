case os.family
when 'debian', 'ubuntu'
  describe file('/etc/iptables/rules.v4') do
    it { should exist }
  end
  describe service('netfilter-persistent') do
    it { should be_installed }
    it { should_not be_running }
    it { should_not be_enabled }
  end
when 'redhat', 'fedora'
  describe file('/etc/sysconfig/iptables-config') do
    it { should_not exist }
  end
  describe service('iptables') do
    it { should_not be_installed }
    it { should_not be_running }
    it { should_not be_enabled }
  end
end
