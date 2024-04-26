control 'tag:install_service_is_enabled' do
  only_if { !os_properties.on_docker? }

  describe service('rsyslog') do
    it { should be_installed }
    it { should be_enabled }
    # it { should be_running }
  end
end
