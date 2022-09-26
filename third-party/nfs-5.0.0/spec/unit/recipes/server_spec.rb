require_relative '../../spec_helper'

describe 'nfs::server' do
  context 'on centos' do
    platform 'centos'

    it { is_expected.to include_recipe('nfs::_common') }

    it { is_expected.to start_service('nfs-server.service') }
    it { is_expected.to enable_service('nfs-server.service') }
  end

  context 'on debian' do
    platform 'debian'

    it { is_expected.to include_recipe('nfs::_common') }

    it { is_expected.to start_service('nfs-kernel-server.service') }
    it { is_expected.to enable_service('nfs-kernel-server.service') }

    it do
      is_expected.to render_file('/etc/default/nfs-kernel-server')
        .with_content(/RPCMOUNTDOPTS="-p +32767"/)
        .with_content(/RPCNFSDCOUNT="8"/)
    end
  end
end
