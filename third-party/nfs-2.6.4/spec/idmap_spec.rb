require 'spec_helper'

describe 'nfs::_idmap' do
  %w(6.8 5.11).each do |release|
    context "on Centos #{release}" do
      cached(:chef_run) do
        ChefSpec::ServerRunner.new(platform: 'centos', version: release).converge(described_recipe)
      end

      it 'includes recipe nfs::_common' do
        expect(chef_run).to include_recipe('nfs::_common')
      end

      it 'renders file idmapd with /var/lib/nfs/rpc_pipefs' do
        expect(chef_run).to render_file('/etc/idmapd.conf').with_content(%r{Pipefs-Directory += +/var/lib/nfs/rpc_pipefs})
      end

      %w(rpcidmapd).each do |svc|
        it "starts the #{svc} service" do
          expect(chef_run).to start_service(svc)
        end

        it "enables the #{svc} service" do
          expect(chef_run).to enable_service(svc)
        end
      end
    end
  end

  %w(2014.09).each do |release|
    context "on Amazon Linux #{release}" do
      cached(:chef_run) do
        ChefSpec::ServerRunner.new(platform: 'amazon', version: release).converge(described_recipe)
      end

      it 'includes recipe nfs::_common' do
        expect(chef_run).to include_recipe('nfs::_common')
      end

      it 'renders file idmapd with /var/lib/nfs/rpc_pipefs' do
        expect(chef_run).to render_file('/etc/idmapd.conf').with_content(%r{Pipefs-Directory += +/var/lib/nfs/rpc_pipefs})
      end

      %w(rpcidmapd).each do |svc|
        it "starts the #{svc} service" do
          expect(chef_run).to start_service(svc)
        end

        it "enables the #{svc} service" do
          expect(chef_run).to enable_service(svc)
        end
      end
    end
  end

  %w(16.04 14.04 12.04).each do |release|
    context "on Ubuntu #{release}" do
      cached(:chef_run) do
        ChefSpec::ServerRunner.new(platform: 'ubuntu', version: release).converge(described_recipe)
      end

      it 'includes recipe nfs::_common' do
        expect(chef_run).to include_recipe('nfs::_common')
      end

      it 'creates file /etc/idmapd.conf with /run/rpc_pipefs' do
        expect(chef_run).to render_file('/etc/idmapd.conf').with_content(%r{Pipefs-Directory += +/run/rpc_pipefs})
      end

      it 'Does not install nfs-kernel-server' do
        expect(chef_run).to_not install_package('nfs-kernel-server')
      end

      idmap_svc = if release == '16.04'
                    'nfs-idmapd'
                  else
                    'idmapd'
                  end

      it "starts the #{idmap_svc} service" do
        expect(chef_run).to start_service(idmap_svc)
      end

      it "enables the #{idmap_svc} service" do
        expect(chef_run).to enable_service(idmap_svc)
      end
    end
  end

  %w(8.2 7.2).each do |release|
    context "on Debian #{release}" do
      cached(:chef_run) do
        ChefSpec::ServerRunner.new(platform: 'debian', version: release).converge(described_recipe)
      end

      it 'includes recipe nfs::_common' do
        expect(chef_run).to include_recipe('nfs::_common')
      end

      it 'creates file /etc/idmapd.conf with /var/lib/nfs/rpc_pipefs' do
        expect(chef_run).to render_file('/etc/idmapd.conf').with_content(%r{/var/lib/nfs/rpc_pipefs})
      end

      it 'Does not install nfs-kernel-server' do
        expect(chef_run).to_not install_package('nfs-kernel-server')
      end

      %w(nfs-common).each do |nfs|
        it "starts the #{nfs} service" do
          expect(chef_run).to start_service(nfs)
        end

        it "enables the #{nfs} service" do
          expect(chef_run).to enable_service(nfs)
        end
      end
    end
  end
end
