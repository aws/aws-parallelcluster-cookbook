describe command('/sbin/iptables-save') do
  its(:stdout) { should match /\*filter/ }
  its(:stdout) { should match /:INPUT\sACCEPT\s\[\d+\:\d+\]/ }
  its(:stdout) { should match /:FORWARD\sACCEPT\s\[\d+\:\d+\]/ }
  # eth 0 should be the first rule
  its(:stdout) { should match /:OUTPUT\sACCEPT\s\[\d+\:\d+\]/ }
  # lo should be the second rule
  its(:stdout) { should match /\-A\sINPUT\s\-i\seth0\s\-j\sACCEPT/ }
end
