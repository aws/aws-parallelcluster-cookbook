include_controls 'common'

control 'port' do
  title 'Verify that SELinux port contexts are set correctly'

  describe command('seinfo --portcon') do
    its('stdout') { should match 'portcon tcp 29000 system_u:object_r:http_port_t:s0' }
    its('stdout') { should match 'portcon udp 29000 system_u:object_r:http_port_t:s0' }
    its('stdout') { should match 'portcon tcp 29001 system_u:object_r:ssh_port_t:s0' }
    its('stdout') { should match 'portcon tcp 8080 system_u:object_r:http_port_t:s0' }
    its('stdout') { should match 'portcon tcp 8081 system_u:object_r:http_port_t:s0' }
  end
end
