
control 'tag:install_c_states_kernel_configured' do
  title 'Check the configuration to disable c states'
  only_if { !os_properties.on_docker? && os_properties.x86? }

  describe file('/etc/default/grub') do
    it { should exist }
    its('content') { should match(/processor.max_cstate=1/) }
    its('content') { should match(/intel_idle.max_cstate=1/) }
  end

  if os_properties.redhat8? || os_properties.alinux2? || os_properties.centos7? || os_properties.rocky8?

    describe file('/boot/grub2/grub.cfg') do
      it { should exist }
      its('content') { should match(/processor.max_cstate=1/) }
      its('content') { should match(/intel_idle.max_cstate=1/) }
    end

  elsif os.debian?

    describe file('/boot/grub/grub.cfg') do
      it { should exist }
      its('content') { should match(/processor.max_cstate=1/) }
      its('content') { should match(/intel_idle.max_cstate=1/) }
    end
  end
end

control 'tag:config_c_states_disabled' do
  only_if { os_properties.x86? && !os_properties.on_docker? }

  describe bash("cat /sys/module/intel_idle/parameters/max_cstate") do
    its('stdout') { should cmp 1 }
  end
end
