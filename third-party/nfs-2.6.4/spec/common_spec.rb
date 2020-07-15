require 'spec_helper'

describe 'nfs::_common' do
  context 'on Centos 5.11' do
    cached(:chef_run) do
      ChefSpec::ServerRunner.new(platform: 'centos', version: 5.11).converge(described_recipe)
    end

    %w(nfs-utils portmap).each do |pkg|
      it "installs packages #{pkg}" do
        expect(chef_run).to install_package(pkg)
      end
    end

    %w(portmap nfslock).each do |svc|
      it "starts the #{svc} service" do
        expect(chef_run).to start_service(svc)
      end

      it "enables the #{svc} service" do
        expect(chef_run).to enable_service(svc)
      end
    end

    {
      STATD_PORT: 32_765,
      STATD_OUTGOING_PORT: 32_766,
      MOUNTD_PORT: 32_767,
      LOCKD_UDPPORT: 32_768,
      RPCNFSDCOUNT: 8,
    }.each do |svc, port|
      it "creates /etc/sysconfig/nfs with #{svc} defined as #{port}" do
        expect(chef_run).to render_file('/etc/sysconfig/nfs').with_content(/#{svc}="#{port}"/)
      end
    end
  end

  context 'on Centos 6.8' do
    cached(:chef_run) do
      ChefSpec::ServerRunner.new(platform: 'centos', version: 6.8).converge(described_recipe)
    end

    %w(nfs-utils rpcbind).each do |pkg|
      it "installs packages #{pkg}" do
        expect(chef_run).to install_package(pkg)
      end
    end

    %w(portmap nfslock).each do |svc|
      it "starts the #{svc} service" do
        expect(chef_run).to start_service(svc)
      end

      it "enables the #{svc} service" do
        expect(chef_run).to enable_service(svc)
      end
    end

    {
      STATD_PORT: 32_765,
      STATD_OUTGOING_PORT: 32_766,
      MOUNTD_PORT: 32_767,
      LOCKD_UDPPORT: 32_768,
      RPCNFSDCOUNT: 8,
    }.each do |svc, port|
      it "creates /etc/sysconfig/nfs with #{svc} defined as #{port}" do
        expect(chef_run).to render_file('/etc/sysconfig/nfs').with_content(/#{svc}="#{port}"/)
      end
    end
  end

  context 'on Amazon 2014.09' do
    cached(:chef_run) do
      ChefSpec::ServerRunner.new(platform: 'amazon', version: '2014.09').converge(described_recipe)
    end

    %w(nfs-utils rpcbind).each do |pkg|
      it "installs packages #{pkg}" do
        expect(chef_run).to install_package(pkg)
      end
    end

    %w(portmap nfslock).each do |svc|
      it "starts the #{svc} service" do
        expect(chef_run).to start_service(svc)
      end

      it "enables the #{svc} service" do
        expect(chef_run).to enable_service(svc)
      end
    end

    {
      STATD_PORT: 32_765,
      STATD_OUTGOING_PORT: 32_766,
      MOUNTD_PORT: 32_767,
      LOCKD_UDPPORT: 32_768,
      RPCNFSDCOUNT: 8,
    }.each do |svc, port|
      it "creates /etc/sysconfig/nfs with #{svc} defined as #{port}" do
        pending(chef_run).to render_file('/etc/sysconfig/nfs').with_content(/#{svc}="#{port}"/)
      end
    end
  end

  context 'on FreeBSD' do
    cached(:chef_run) do
      ChefSpec::ServerRunner.new(platform: 'freebsd', version: 9.3).converge(described_recipe)
    end

    %w(nfs-utils rpcbind).each do |pkg|
      it "Does not install default package #{pkg}" do
        expect(chef_run).to_not install_package(pkg)
      end
    end

    %w(rpcbind lockd).each do |svc|
      it "starts the #{svc} service" do
        expect(chef_run).to start_service(svc)
      end

      it "enables the #{svc} service" do
        expect(chef_run).to enable_service(svc)
      end
    end

    it 'creates rc.conf.d directory' do
      expect(chef_run).to create_directory('/etc/rc.conf.d').with(mode: 00755)
    end

    it 'creates /etc/rc.conf.d/mountd with: mountd_flags="-r -p 32767"' do
      expect(chef_run).to render_file('/etc/rc.conf.d/mountd').with_content(/mountd_flags="-r +-p +32767"/)
    end
  end

  # Submit Ubuntu Fauxhai to https://github.com/customink/fauxhai for better Ubuntu coverage
  context 'on Ubuntu 16.04' do
    cached(:chef_run) do
      ChefSpec::ServerRunner.new(platform: 'ubuntu', version: 16.04).converge(described_recipe)
    end

    %w(nfs-common rpcbind).each do |pkg|
      it "installs package #{pkg}" do
        expect(chef_run).to install_package(pkg)
      end
    end

    it 'creates file /etc/default/nfs-common with: STATDOPTS="--port 32765 --outgoing-port 32766' do
      expect(chef_run).to render_file('/etc/default/nfs-common').with_content(/STATDOPTS="--port +32765 +--outgoing-port +32766"/)
    end

    it 'creates file /etc/modprobe.d/lockd.conf with: options lockd nlm_udpport=32768 nlm_tcpport=32768' do
      expect(chef_run).to render_file('/etc/modprobe.d/lockd.conf').with_content(/options +lockd +nlm_udpport=32768 +nlm_tcpport=32768/)
    end

    %w(rpcbind rpc-statd).each do |svc|
      it "starts the #{svc} service" do
        expect(chef_run).to start_service(svc)
      end

      it "enables the #{svc} service" do
        expect(chef_run).to enable_service(svc)
      end
    end
  end

  # Submit Ubuntu Fauxhai to https://github.com/customink/fauxhai for better Ubuntu coverage
  context 'on Ubuntu 14.04' do
    cached(:chef_run) do
      ChefSpec::ServerRunner.new(platform: 'ubuntu', version: 14.04).converge(described_recipe)
    end

    %w(nfs-common rpcbind).each do |pkg|
      it "installs package #{pkg}" do
        expect(chef_run).to install_package(pkg)
      end
    end

    it 'creates file /etc/default/nfs-common with: STATDOPTS="--port 32765 --outgoing-port 32766' do
      expect(chef_run).to render_file('/etc/default/nfs-common').with_content(/STATDOPTS="--port +32765 +--outgoing-port +32766"/)
    end

    it 'creates file /etc/modprobe.d/lockd.conf with: options lockd nlm_udpport=32768 nlm_tcpport=32768' do
      expect(chef_run).to render_file('/etc/modprobe.d/lockd.conf').with_content(/options +lockd +nlm_udpport=32768 +nlm_tcpport=32768/)
    end

    %w(rpcbind statd).each do |svc|
      it "starts the #{svc} service" do
        expect(chef_run).to start_service(svc)
      end

      it "enables the #{svc} service" do
        expect(chef_run).to enable_service(svc)
      end
    end
  end

  # Submit Ubuntu Fauxhai to https://github.com/customink/fauxhai for better Ubuntu coverage
  context 'on Ubuntu 12.04' do
    cached(:chef_run) do
      ChefSpec::ServerRunner.new(platform: 'ubuntu', version: 12.04).converge(described_recipe)
    end

    %w(nfs-common portmap).each do |pkg|
      it "installs package #{pkg}" do
        expect(chef_run).to install_package(pkg)
      end
    end

    it 'creates file /etc/default/nfs-common with: STATDOPTS="--port 32765 --outgoing-port 32766' do
      expect(chef_run).to render_file('/etc/default/nfs-common').with_content(/STATDOPTS="--port +32765 +--outgoing-port +32766"/)
    end

    it 'creates file /etc/modprobe.d/lockd.conf with: options lockd nlm_udpport=32768 nlm_tcpport=32768' do
      expect(chef_run).to render_file('/etc/modprobe.d/lockd.conf').with_content(/options +lockd +nlm_udpport=32768 +nlm_tcpport=32768/)
    end

    %w(portmap statd).each do |svc|
      it "starts the #{svc} service" do
        expect(chef_run).to start_service(svc)
      end

      it "enables the #{svc} service" do
        expect(chef_run).to enable_service(svc)
      end
    end
  end

  context 'on Debian 7.2' do
    cached(:chef_run) do
      ChefSpec::ServerRunner.new(platform: 'debian', version: 7.2).converge(described_recipe)
    end

    %w(nfs-common rpcbind).each do |pkg|
      it "installs package #{pkg}" do
        expect(chef_run).to install_package(pkg)
      end
    end

    it 'creates file /etc/default/nfs-common with: STATDOPTS="--port 32765 --outgoing-port 32766' do
      expect(chef_run).to render_file('/etc/default/nfs-common').with_content(/STATDOPTS="--port +32765 +--outgoing-port +32766"/)
    end

    it 'creates file /etc/modprobe.d/lockd.conf with: options lockd nlm_udpport=32768 nlm_tcpport=32768' do
      expect(chef_run).to render_file('/etc/modprobe.d/lockd.conf').with_content(/options +lockd +nlm_udpport=32768 +nlm_tcpport=32768/)
    end

    %w(nfs-common rpcbind).each do |svc|
      it "starts the #{svc} service" do
        expect(chef_run).to start_service(svc)
      end

      it "enables the #{svc} service" do
        expect(chef_run).to enable_service(svc)
      end
    end
  end

  context 'on Debian 8.2' do
    cached(:chef_run) do
      ChefSpec::ServerRunner.new(platform: 'debian', version: 8.2).converge(described_recipe)
    end

    %w(nfs-common rpcbind).each do |pkg|
      it "installs package #{pkg}" do
        expect(chef_run).to install_package(pkg)
      end
    end

    it 'creates file /etc/default/nfs-common with: STATDOPTS="--port 32765 --outgoing-port 32766' do
      expect(chef_run).to render_file('/etc/default/nfs-common').with_content(/STATDOPTS="--port +32765 +--outgoing-port +32766"/)
    end

    it 'creates file /etc/modprobe.d/lockd.conf with: options lockd nlm_udpport=32768 nlm_tcpport=32768' do
      expect(chef_run).to render_file('/etc/modprobe.d/lockd.conf').with_content(/options +lockd +nlm_udpport=32768 +nlm_tcpport=32768/)
    end

    %w(nfs-common rpcbind).each do |svc|
      it "starts the #{svc} service" do
        expect(chef_run).to start_service(svc)
      end

      it "enables the #{svc} service" do
        expect(chef_run).to enable_service(svc)
      end
    end
  end
end
