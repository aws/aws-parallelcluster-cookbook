control 'efa_debian_system_settings_configured' do
  title 'Check debian system is correctly configured for EFA'

  only_if { os.debian? && !os_properties.virtualized? }

  ptrace_scope = instance.head_node? ? 1 : 0
  if ptrace_scope == 1
    describe 'Verify ptrace config file is not present' do
      subject { file('/etc/sysctl.d/99-chef-kernel.yama.ptrace_scope.conf') }
      it { should_not exist }
    end
  else
    describe 'Verify ptrace config file is present' do
      subject { file('/etc/sysctl.d/99-chef-kernel.yama.ptrace_scope.conf') }
      it { should exist }
      its('content') { should match /kernel.yama.ptrace_scope = #{ptrace_scope}/ }
    end
  end

  describe kernel_parameter('kernel.yama.ptrace_scope') do
    its('value') { should eq ptrace_scope }
  end
end
