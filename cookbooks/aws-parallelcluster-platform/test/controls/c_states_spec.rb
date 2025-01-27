
control 'tag:install_c_states_kernel_configured' do
  title 'Check the configuration to disable c states'
  only_if { !os_properties.on_docker? && os_properties.x86? }

  if os_properties.ubuntu2004?
    describe file('/etc/default/grub') do
      it { should exist }
      its('content') { should match(/processor.max_cstate=1/) }
      its('content') { should match(/intel_idle.max_cstate=1/) }
    end
    describe file('/boot/grub/grub.cfg') do
      it { should exist }
      its('content') { should match(/processor.max_cstate=1/) }
      its('content') { should match(/intel_idle.max_cstate=1/) }
    end
  else
    describe bash('cpupower idle-info') do
      its('stdout') { should match(/Number of idle states: 2/) }
      its('stdout') { should match(/Available idle states: POLL C1/) }
    end
  end
end

control 'tag:config_c_states_disabled' do
  only_if { os_properties.x86? && !os_properties.on_docker? }

  describe bash("cat /sys/module/intel_idle/parameters/max_cstate") do
    its('stdout') { should cmp 1 }
  end
end
