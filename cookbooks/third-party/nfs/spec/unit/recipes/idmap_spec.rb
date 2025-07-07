require_relative '../../spec_helper'

describe 'nfs::_idmap' do
  context 'on centos' do
    platform 'centos'

    it { is_expected.to include_recipe('nfs::_common') }

    it do
      is_expected.to render_file('/etc/idmapd.conf')
        .with_content(%r{Pipefs-Directory += +/var/lib/nfs/rpc_pipefs})
    end

    it { is_expected.to start_service('nfs-idmapd.service') }
    it { is_expected.to enable_service('nfs-idmapd.service') }
  end

  context 'on debian' do
    platform 'debian'

    it { is_expected.to include_recipe('nfs::_common') }

    it do
      is_expected.to render_file('/etc/idmapd.conf')
        .with_content(%r{Pipefs-Directory += +/run/rpc_pipefs})
    end

    it { is_expected.to start_service('nfs-idmapd.service') }
    it { is_expected.to enable_service('nfs-idmapd.service') }
  end
end
