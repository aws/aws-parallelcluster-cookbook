control 'nfs' do
  title 'NFS resource'

  if virtualization.system != 'docker'
    # Check nfsd process is running
    describe command('ps aux') do
      its('stdout') { should match(/nfsd/) }
    end

    # Check version of NFS
    describe command("rpcinfo -p localhost") do
      its('stdout') { should match(/4.*tcp.*2049.*nfs/) }
    end
  end
end
