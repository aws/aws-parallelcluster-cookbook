require_relative '../../spec_helper'

describe 'nfs::default' do
  platform 'centos'

  it { is_expected.to include_recipe('nfs::_common') }
end
