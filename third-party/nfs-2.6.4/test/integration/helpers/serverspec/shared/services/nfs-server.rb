shared_examples 'services::nfs-server' do
  context 'nfs-server' do
    name = 'nfs-server'
    name = '' if host_inventory[:platform_version].to_i == 5
    name = 'nfs' if host_inventory[:platform_version].to_i == 6

    describe service(name) do
      it { should be_enabled }
      it { should be_running }
    end unless name == ''
  end
end
