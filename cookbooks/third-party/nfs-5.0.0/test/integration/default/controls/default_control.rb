control 'portmap' do
  title 'Verify portmap is setup correctly'

  describe port(111) do
    it { should be_listening }
  end

  describe service('rpcbind') do
    it { should be_enabled }
    it { should be_running }
  end
end

control 'statd' do
  title 'Verify statd is setup correctly'

  describe port(32765) do
    it { should be_listening }
  end

  describe service('rpc-statd') do
    it { should be_enabled }
    it { should be_running }
  end
end

control 'nfs-client' do
  title 'Verify nfs client services are setup correctly'

  describe service('nfs-client.target') do
    it { should be_enabled }
    it { should be_running }
  end
end
