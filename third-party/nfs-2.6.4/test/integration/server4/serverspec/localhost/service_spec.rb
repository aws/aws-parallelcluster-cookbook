require 'spec_helper'

describe 'Server4 Tests' do
  include_examples 'issues::server'
  include_examples 'server_ports'
  include_examples 'redhat::server_services'

  describe 'NFS Server4 Services' do
    describe 'RHEL', if: os['family'] == 'redhat' do
      describe '6.x', if: host_inventory['platform_version'].to_i == 6 do
        describe service('rpcidmapd') do
          it { should be_enabled }
          it { should be_running }
        end
      end

      describe '7.0', if: host_inventory['platform_version'].to_f == 7.0 do
        describe service('nfs-idmap') do
          it { should be_enabled }
          it { should be_running }
        end
      end
    end
  end
end
