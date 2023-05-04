require_relative '../../spec_helper'

describe 'nfs::_common' do
  context 'on centos 7' do
    platform 'centos', '7'

    it { is_expected.to install_package('nfs-utils') }
    it { is_expected.to install_package('rpcbind') }

    %w(
      nfs-client.target
      rpc-statd.service
    ).each do |service|
      it { is_expected.to start_service(service) }
      it { is_expected.to enable_service(service) }
    end

    it do
      is_expected.to render_file('/etc/sysconfig/nfs')
        .with_content(/STATD_PORT="32765"/)
        .with_content(/STATD_OUTGOING_PORT="32766"/)
        .with_content(/MOUNTD_PORT="32767"/)
        .with_content(/LOCKD_UDPPORT="32768"/)
        .with_content(/RPCNFSDCOUNT="8"/)
    end
  end

  context 'on centos 8' do
    platform 'centos', '8'

    it { is_expected.to install_package('nfs-utils') }
    it { is_expected.to install_package('rpcbind') }

    %w(
      nfs-client.target
      rpc-statd.service
    ).each do |service|
      it { is_expected.to start_service(service) }
      it { is_expected.to enable_service(service) }
    end

    it do
      is_expected.to render_file('/etc/nfs.conf')
        .with_content(/\[statd\]\nport=32765\noutgoing-port=32766/)
        .with_content(/\[mountd\]\nport=32767/)
        .with_content(/\[lockd\]\nport=32768\nudp-port=32768/)
        .with_content(/\[nfsd\]\nthreads=8/)
    end
  end

  context 'on debian' do
    platform 'debian'

    it { is_expected.to install_package('nfs-common') }
    it { is_expected.to install_package('rpcbind') }

    %w(
      nfs-client.target
      rpc-statd.service
    ).each do |service|
      it { is_expected.to start_service(service) }
      it { is_expected.to enable_service(service) }
    end

    it do
      is_expected.to render_file('/etc/default/nfs-common')
        .with_content(/STATDOPTS="--port 32765 --outgoing-port 32766"/)
    end
  end
end
