require 'spec_helper'

describe 'yum::default' do
  platform 'centos'

  it do
    expect(chef_run).to create_yum_globalconfig('/etc/yum.conf')
  end
end
