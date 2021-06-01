require 'spec_helper'

shared_examples 'server on Generic Linux' do |platform, version|
  context "On #{platform} #{version}" do
    cached(:chef_run) do
      ChefSpec::ServerRunner.new(platform: platform, version: version).converge(described_recipe)
    end

    it 'includes recipe nfs::_common' do
      expect(chef_run).to include_recipe('nfs::_common')
    end

    svc = if platform == 'debian' || platform == 'ubuntu'
            'nfs-kernel-server.service'
          else
            'nfs-server.service'
          end
  
    it "starts the #{svc} service" do
      expect(chef_run).to start_service(svc)
    end

    it "enables the #{svc} service" do
      expect(chef_run).to enable_service(svc)
    end

    if platform == 'debian' or platform == 'ubuntu'
      it 'creates file /etc/default/nfs-kernel-server with: RPCMOUNTDOPTS="-p 32767"' do
        expect(chef_run).to render_file('/etc/default/nfs-kernel-server').with_content(/RPCMOUNTDOPTS="-p +32767"/)
      end

      it 'creates file /etc/default/nfs-kernel-server with: RPCNFSDCOUNT="8"' do
          expect(chef_run).to render_file('/etc/default/nfs-kernel-server').with_content(/RPCNFSDCOUNT="8"/)
      end
    end
  end
end

describe 'nfs::server' do
  platforms = {
    'centos' => ['7.7.1908', '8'],
    'ubuntu' => ['16.04', '18.04', '20.04'],
    'debian' => ['10']
  }

  platforms.each do |platform, versions|
    versions.each do |version|
      it_behaves_like 'server on Generic Linux', platform, version
    end
  end
end