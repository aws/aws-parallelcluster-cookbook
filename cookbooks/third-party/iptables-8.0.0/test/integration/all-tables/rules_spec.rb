describe command('/sbin/iptables-save') do
  its(:stdout) { should match /\*filter/ }
  its(:stdout) { should match /\*mangle/ }
  its(:stdout) { should match /\*nat/ }
  its(:stdout) { should match /\*raw/ }
  its(:stdout) { should match /\*security/ }
end
