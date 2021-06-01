shared_examples 'ports::mountd' do
  context 'mountd' do
    describe port(32_767) do
      it { should be_listening.with('tcp') }
      it { should be_listening.with('udp') }
    end
  end
end

shared_examples 'services::mountd' do
  context 'mountd' do
    name = 'mountd'
    check_enabled = true
    check_running = true

    # RHEL/CentOS
    if os[:family] == 'redhat'
      check_enabled = false
      name = 'nfs-mountd' if host_inventory[:platform_version].to_f >= 7.0
    elsif os[:family] == 'amazon'
      check_enabled = false
    elsif os[:family] == 'suse'
      name = 'nfsserver'
    elsif host_inventory[:platform] == 'ubuntu' &&
          host_inventory[:platform_version].to_i >= 15
      # Static ports on Ubuntu 16.04 do not appear to work
      check_running = false
      name = 'nfs-mountd'
    else
      name = 'nfs-kernel-server'
    end

    describe service(name) do
      it { should be_enabled } if check_enabled
      it { should be_running } if check_running
    end unless name == ''

    include_examples 'ports::mountd' if check_running
  end
end
