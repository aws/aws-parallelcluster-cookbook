# Test restart
control 'network_service_running' do
  only_if { !os_properties.on_docker? }
  title "Check the network service is running"
  network_service_name = case node['platform']
                         when 'amazon', 'centos'
                           'network'
                         when 'redhat'
                           'NetworkManager'
                         when 'ubuntu'
                           'systemd-resolved'
                         end
  describe service(network_service_name) do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end
end
