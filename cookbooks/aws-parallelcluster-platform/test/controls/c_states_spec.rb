
control 'tag:install_c_states_kernel_configured' do
  title 'Check the configuration to disable c states'
  only_if { !os_properties.virtualized? && os_properties.x86? }

  describe file('/etc/default/grub') do
    it { should exist }
    its('content') { should match(/processor.max_cstate=1/) }
    its('content') { should match(/intel_idle.max_cstate=1/) }
  end

  if os.redhat? # redhat includes amazon

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

  else
    describe "unsupported OS" do
      # this produces a skipped control (ignore-like)
      # adding a new OS to kitchen platform list and running the tests,
      # it would surface the fact this recipe does not support this OS.
      pending "support for #{os.name}-#{os.release} needs to be implemented"
    end
  end
end

control 'tag:config_c_states_disabled' do
  only_if { os_properties.x86? && !os_properties.on_docker? }

  describe bash("cat /sys/module/intel_idle/parameters/max_cstate") do
    its('stdout') { should cmp 1 }
  end
end
