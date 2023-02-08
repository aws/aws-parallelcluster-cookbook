
control 'c_states_kernel_configuration' do
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
