if %w(redhat fedora amazon).include?(os[:family])
  describe service('iptables') do
    it { should be_installed }
    it { should_not be_enabled }
    it { should_not be_running }
  end
end
# some RHEL/CentOS versions use these files to persist rules. disable recipe
# "clears" these files out.
%w(/etc/sysconfig/iptables /etc/sysconfig/iptables.fallback).each do |file|
  describe file(file) do
    before :each do
      skip if os[:family] != 'redhat'
    end
    it { should exist }
    it { should be_file }
    its(:content) { should match(/^# iptables rules files cleared by chef via iptables::disabled$/) }
  end
end
