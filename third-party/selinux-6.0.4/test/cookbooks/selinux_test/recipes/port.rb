%w(tcp udp).each do |prot|
  selinux_port '29000' do
    protocol prot
    secontext 'http_port_t'
  end
end

selinux_port '29001' do
  protocol 'tcp'
  secontext 'ssh_port_t'
end

%w(8080 8081).each do |port|
  selinux_port port do
    protocol 'tcp'
    secontext 'http_port_t'
  end
end
