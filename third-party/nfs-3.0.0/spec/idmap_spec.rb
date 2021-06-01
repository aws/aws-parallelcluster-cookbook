require 'spec_helper'

shared_examples '_idmap on Generic Linux' do |platform, version|
  context "On #{platform} #{version}" do
    cached(:chef_run) do
      ChefSpec::ServerRunner.new(platform: platform, version: version).converge(described_recipe)
    end

    it 'includes recipe nfs::_common' do
      expect(chef_run).to include_recipe('nfs::_common')
    end

    pipefs_tree = if platform == 'debian' || platform == 'ubuntu'
                  '/run/rpc_pipefs'
                else
                  '/var/lib/nfs/rpc_pipefs'
                end
    it "renders file idmapd with #{pipefs_tree}" do
      expect(chef_run).to render_file('/etc/idmapd.conf').with_content(/Pipefs-Directory += +#{pipefs_tree}/)
    end

    %w(nfs-idmapd.service).each do |svc|
      it "starts the #{svc} service" do
        expect(chef_run).to start_service(svc)
      end

      it "enables the #{svc} service" do
        expect(chef_run).to enable_service(svc)
      end
    end
  end
end

describe 'nfs::_idmap' do
  platforms = {
    'centos' => ['7.7.1908', '8'],
    'ubuntu' => ['16.04', '18.04', '20.04'],
    'debian' => ['10']
  }

  platforms.each do |platform, versions|
    versions.each do |version|
      it_behaves_like '_idmap on Generic Linux', platform, version
    end
  end
end