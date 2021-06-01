shared_examples 'ports::portmap' do
  context 'portmap/rpcbind' do
    describe port(111) do
      it { should be_listening.with('tcp') }
      it { should be_listening.with('udp') }
    end
  end
end

shared_examples 'services::portmap' do
  context 'portmap/rpcbind' do
    name = 'rpcbind'
    check_enabled = true
    check_running = true

    # RHEL/CentOS
    if os[:family] == 'redhat'
      name = 'portmap' if host_inventory[:platform_version].to_i <= 5

      if host_inventory[:platform_version].to_f >= 7.1
        name = 'rpcbind'
        # Due to lazy-starting services, this needs a kick to wake up
        describe command("systemctl start #{name}") do
          its(:exit_status) { should eq 0 }
        end
        check_enabled = false
      end
    elsif os[:family] == 'amazon'
      name = 'rpcbind'
    elsif %w(debian ubuntu).include?(os[:family])
      # Ubuntu
      if host_inventory[:platform_version].to_i >= 12 &&
         host_inventory[:platform_version].to_i <= 13
        name = 'rpcbind-boot'
        check_running = false
      elsif host_inventory[:platform_version].to_i <= 6
        name = 'portmap'
      else
        name = 'rpcbind'
      end
    end

    describe service(name) do
      it { should be_enabled } if check_enabled
      it { should be_running } if check_running
    end unless name == ''

    include_examples 'ports::portmap' # unless name == ''
  end
end
