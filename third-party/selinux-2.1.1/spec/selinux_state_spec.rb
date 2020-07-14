require 'spec_helper'

describe 'selinux_state_test::default' do
  cached(:chef_run) do
    ChefSpec::SoloRunner.new.converge(described_recipe)
  end

  it 'enforcing selinux' do
    expect(chef_run).to enforcing_selinux_state('enforcing')
  end

  it 'disabled selinux' do
    expect(chef_run).to disabled_selinux_state('disabled')
  end

  it 'permissive selinux' do
    expect(chef_run).to permissive_selinux_state('permissive')
  end
end
