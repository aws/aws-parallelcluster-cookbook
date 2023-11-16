control 'tag:install_nfs_installed_with_right_version' do
  title 'Check NFS process is running and installed version'

  only_if { !os_properties.on_docker? }

  # Check nfsd process is running
  describe command('ps aux') do
    its('stdout') { should match(/nfsd/) }
  end

  # Check version of NFS
  describe "Verify installed NFS version is 4\n" do
    nfs_version = command("rpcinfo -p localhost | awk '{print $5$2}' | grep nfs4")
    describe nfs_version do
      its('stdout') { should match "nfs4" }
    end
  end
end

control 'tag:config_nfs_configured_on_head_node' do
  title 'Check that nfs is configured correctly'

  only_if { instance.head_node? && !os_properties.on_docker? }

  describe 'Check nfs service is restarted'
  nfs_server = os.debian? ? 'nfs-kernel-server.service' : 'nfs-server.service'
  describe service(nfs_server) do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end

  describe 'Check that the number of nfs threads is correct'
  describe bash("grep th /proc/net/rpc/nfsd | awk '{print $2}'") do
    its('exit_status') { should eq 0 }
    its('stdout') { should cmp [[node['cpu']['cores'].to_i * 4, 8].max, 256].min }
  end

  describe 'check for nfs server protocol' do
    subject { command "sudo -u #{node['cluster']['cluster_user']} rpcinfo -p localhost | awk '{print $2$5}' | grep 4nfs" }
    its('exit_status') { should eq 0 }
  end

  describe bash("cat /proc/net/rpc/nfsd | grep th | awk '{print$2}'") do
    its('stdout') { should cmp node['cluster']['nfs']['threads'] }
  end
end

control 'tag:config_nfs_correctly_installed_on_compute_node' do
  only_if { instance.compute_node? && !os_properties.on_docker? }

  describe 'check for nfs server protocol' do
    subject { command "sudo -u #{node['cluster']['cluster_user']} systemctl status #{node['nfs']['service']['server']} | grep inactive" }
    its('exit_status') { should eq 0 }
  end
end
