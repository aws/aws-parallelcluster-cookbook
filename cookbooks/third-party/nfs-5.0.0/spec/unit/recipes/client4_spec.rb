require_relative '../../spec_helper'

describe 'nfs::client4' do
  platform 'centos'

  %w(nfs::_common nfs::_idmap).each do |component|
    it { is_expected.to include_recipe(component) }
  end
end
