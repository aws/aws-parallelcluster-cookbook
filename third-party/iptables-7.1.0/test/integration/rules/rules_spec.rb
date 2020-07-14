describe command('/sbin/iptables-save') do
  its(:stdout) { should match /\*filter/ }
  its(:stdout) { should match /:INPUT\sACCEPT\s\[\d+\:\d+\]/ }
  its(:stdout) { should match /:OUTPUT\sACCEPT\s\[\d+\:\d+\]/ }
  its(:stdout) { should match /:FORWARD\sACCEPT\s\[\d+\:\d+\]/ }
  its(:stdout) { should match /-A INPUT -p icmp -j ACCEPT/ }

  its(:stdout) { should match /\*mangle/ }
  its(:stdout) { should match /:INPUT\sACCEPT\s\[\d+\:\d+\]/ }
  its(:stdout) { should match /:FORWARD\sACCEPT\s\[\d+\:\d+\]/ }
  its(:stdout) { should match /:OUTPUT\sACCEPT\s\[\d+\:\d+\]/ }
  its(:stdout) { should match /:POSTROUTING\sACCEPT\s\[\d+\:\d+\]/ }

  its(:stdout) { should match /\*mangle/ }
  its(:stdout) { should match /:DIVERT\s-\s\[\d+\:\d+\]\s+\-A/m }
  its(:stdout) { should match /\-A\sPREROUTING\s\-p\stcp\s\-m\ssocket\s\-j\sDIVERT/ }
  its(:stdout) { should match %r{\-A\sDIVERT\s\-j\sMARK\s\-\-set\-xmark\s0x1/0xffffffff} }
  its(:stdout) { should match /\-A\sDIVERT\s\-j\sACCEPT/m }
end
