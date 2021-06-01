# RHEL/CentOS 7.1 does some strange things and we need to check for nfs-client.target.
# At present, specinfra doesn't handle checking for *.target systemd units, so some
# manual work is required.
# It also lazy-starts some services at the first mount. I have not yet found a way
# to reliably test NFS mounts.

shared_examples 'services::nfs-client' do
  context 'nfs-client' do
    name = 'nfs-client.target'

    name = 'nfs.target' if host_inventory[:platform_version] == '7.0.1406'

    describe command("systemctl is-enabled #{name}") do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should contain('enabled') }
    end
    describe service(name) do
      it { should be_running }
    end
  end
end
