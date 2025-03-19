
control 'tag:install_c_states_kernel_configured' do
  title 'Check the configuration to disable c states'
  only_if { !os_properties.on_docker? && os_properties.x86? }
  ## cpupower is installed for Ubuntu >=22
  describe bash('cpupower idle-info') do
    its('stdout') { should match(/Number of idle states: 2/) }
    its('stdout') { should match(/Available idle states: POLL C1/) }
  end
end

control 'tag:config_c_states_disabled' do
  only_if { os_properties.x86? && !os_properties.on_docker? }

  describe bash("cat /sys/module/intel_idle/parameters/max_cstate") do
    its('stdout') { should cmp 1 }
  end
end
