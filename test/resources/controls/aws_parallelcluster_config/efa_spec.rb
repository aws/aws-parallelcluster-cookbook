control 'efa_debian_system_settings_configured' do
  title 'Check debian system is correctly configured for EFA'

  only_if { os.debian? && !os_properties.virtualized? }

  describe kernel_parameter('kernel.yama.ptrace_scope') do
    its('value') { should eq 0 }
  end
end
