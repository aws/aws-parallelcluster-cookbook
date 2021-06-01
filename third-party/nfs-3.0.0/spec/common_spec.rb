require 'spec_helper'

shared_examples '_common on Generic Linux' do |platform, version|
  context "On #{platform} #{version}" do
    cached(:chef_run) do
      ChefSpec::ServerRunner.new(platform: platform, version: version).converge(described_recipe)
    end

    packages = if platform == 'debian' || platform == 'ubuntu'
                 %w(nfs-common rpcbind)
               else
                 %w(nfs-utils rpcbind)
               end

    packages.each do |pkg|
      it "installs packages #{pkg}" do
        expect(chef_run).to install_package(pkg)
      end
    end

    %w(nfs-client.target).each do |svc|
      it "starts the #{svc} service" do
        expect(chef_run).to start_service(svc)
      end

      it "enables the #{svc} service" do
        expect(chef_run).to enable_service(svc)
      end
    end

    config = if platform == 'debian' || platform == 'ubuntu'
               '/etc/default/nfs-common'
             else
               '/etc/sysconfig/nfs'
             end

    ports = {
      STATD_PORT: 32_765,
      STATD_OUTGOING_PORT: 32_766,
      MOUNTD_PORT: 32_767,
      LOCKD_UDPPORT: 32_768,
      RPCNFSDCOUNT: 8,
    }           
    if platform == 'rhel' || platform == 'centos'
      ports.each do |svc, port|
        it "creates #{config} with #{svc} defined as #{port}" do
          expect(chef_run).to render_file(config).with_content(/#{svc}="#{port}"/)
        end
      end
    elsif platform == 'debian' || platform == 'ubuntu'
      it "creates #{config} with statd ports #{ports[:STATD_PORT]} and #{ports[:STATD_OUTGOING_PORT]}" do
        expect(chef_run).to render_file(config).with_content(/STATDOPTS="--port #{ports[:STATD_PORT]} --outgoing-port #{ports[:STATD_OUTGOING_PORT]}/)
      end
    end
  end
end

describe 'nfs::_common' do
  platforms = {
    'centos' => ['7.7.1908', '8'],
    'ubuntu' => ['16.04', '18.04', '20.04'],
    'debian' => ['10']
  }

  platforms.each do |platform, versions|
    versions.each do |version|
      it_behaves_like '_common on Generic Linux', platform, version
    end
  end
end
