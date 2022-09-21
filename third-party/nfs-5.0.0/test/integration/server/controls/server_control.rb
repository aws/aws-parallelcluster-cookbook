include_controls 'default'

control 'mountd' do
  title 'Verify mountd is setup correctly'

  describe port(32767) do
    it { should be_listening }
  end

  describe service('nfs-mountd') do
    it { should be_enabled }
    it { should be_running }
  end
end

control 'nfs-server' do
  title 'Verify nfs-server is setup correctly'

  describe service('nfs-server') do
    it { should be_enabled }
    it { should be_running }
  end
end

control 'share-ids' do
  title 'Verify correct user/group ids are used'

  describe command("egrep -c '/tmp/share[0-9] 127.0.0.1\\(ro,sync,root_squash,anonuid=[0-9]+,anongid=[0-9]+(,fsid=root)?\\)' /etc/exports") do
    its('stdout') { should match(/3\n/) }
  end

  describe command("egrep -v '/tmp/share[0-9] 127.0.0.1\\(rw,sync,root_squash,(anonuid=[0-9]+,anongid=[0-9]+){2,}\\)' /etc/exports") do
    its('exit_status') { should eq 0 }
    its('stdout') { should_not match(%r{^\/tmp\/share2[.]*anonuid=1001}) }
    its('stdout') { should_not match(%r{^\/tmp\/share2[.]*anongid=1001}) }
    its('stdout') { should_not match(%r{^\/tmp\/share3[.]*anonuid=1002}) }
    its('stdout') { should_not match(%r{^\/tmp\/share3[.]*anongid=1002}) }
  end
end

control 'lockd kernel module' do
  title 'Verify kernel module is setup correctly'

  describe kernel_module 'lockd' do
    it { should be_loaded }
    it { should_not be_disabled }
    it { should_not be_blacklisted }
  end

  %w(fs.nfs.nlm_tcpport fs.nfs.nlm_udpport).each do |param|
    describe kernel_parameter param do
      its('value') { should eq 32768 }
    end
  end
end
