shared_examples 'ports::lockd' do
  context 'lockd' do
    describe port(32_768) do
      it { should be_listening.with('tcp') }
      it { should be_listening.with('udp') }
    end
  end
end

shared_examples 'services::lockd' do
  context 'lockd' do
    name = 'lockd'
    check_enabled = true
    check_running = true
    check_listening = true

    # RHEL/CentOS
    if os[:family] == 'redhat'
      name = 'nfslock' if host_inventory[:platform_version].to_i >= 5
      name = 'nfs-lock' if host_inventory[:platform_version].to_f >= 7.0
      # This seems to be a kernel process in 7.1
      if host_inventory[:platform_version].to_f >= 7.1
        check_enabled = false
        check_running = false
        describe process('lockd') do
          it { should be_running }
        end
      end
    elsif os[:family] == 'amazon'
      name = 'nfslock'
    elsif %w(debian ubuntu).include?(os[:family])
      name = 'nfs-common' if os[:family] == 'debian'
      check_running = false
      check_enabled = false if os[:family] == 'ubuntu'
    elsif os[:family] == 'suse'
      name = 'nfsserver'
    end

    describe service(name) do
      it { should be_enabled } if check_enabled
      it { should be_running } if check_running
    end unless name == ''

    include_examples 'ports::lockd' if check_listening
  end
end
