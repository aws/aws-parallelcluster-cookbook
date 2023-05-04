require_relative '../../spec_helper'

describe 'nfs_export' do
  platform 'centos'

  recipe do
    nfs_export 'test'
  end
end
