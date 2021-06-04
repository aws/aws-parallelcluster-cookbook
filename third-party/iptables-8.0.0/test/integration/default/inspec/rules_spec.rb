if os[:family] == 'redhat' && os[:release].start_with?('6')
  describe command('/etc/init.d/iptables status') do
    its(:stdout) { should match /ACCEPT.*tcp dpt:22/ }
  end

  describe command('/etc/init.d/ip6tables status') do
    its(:stdout) { should match /ACCEPT.*tcp dpt:22/ }
  end

else
  describe iptables do
    it { should have_rule('-A FWR -p tcp -m tcp --dport 22 -j ACCEPT') }
  end

  describe command('/sbin/ip6tables-save') do
    its(:stdout) { should match %r{\-A\sINPUT\s\-d\sfe80\:\:/\d+\s\-p\sudp\s\-m\sudp\s\-\-dport\s546\s\-m\sstate\s\-\-state\sNEW\s\-j\sACCEPT} }
  end
end
