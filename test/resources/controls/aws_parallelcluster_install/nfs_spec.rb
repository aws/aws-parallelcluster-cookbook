control 'nfs_installed_with_right_version' do
  title 'Check NFS process is running and installed version'

  only_if { !os_properties.virtualized? }

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
