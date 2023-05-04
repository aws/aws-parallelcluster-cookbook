require_relative '../../spec_helper'

describe 'nfs::server4' do
  platform 'centos'

  %w(nfs::_common nfs::_idmap nfs::server).each do |component|
    it { is_expected.to include_recipe(component) }
  end
end
