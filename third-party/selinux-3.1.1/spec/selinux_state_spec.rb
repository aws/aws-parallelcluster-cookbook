require 'spec_helper'

describe 'selinux_state_test::default' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(platform: 'centos', step_into: ['selinux_state'])
                        .converge(described_recipe)
  end

  before do
    runner = double('shellout_double')
    allow(runner).to receive(:run_command)
    allow(runner).to receive(:stdout).and_return('Permissive')
    allow_any_instance_of(Chef::Mixin::ShellOut).to(
      receive(:shell_out).with('getenforce').and_return(runner))

    stub_command(/getenforce.*?grep/).and_return(false)
    stub_command(/setenforce/).and_return(true)
    stub_command('selinuxenabled').and_return('')
  end

  it 'enforcing selinux' do
    expect(chef_run).to(
      ChefSpec::Matchers::ResourceMatcher.new(
        :selinux_state, :enforcing, 'enforcing'))
    expect(chef_run).to(
      run_execute('selinux-enforcing').with_command('/usr/sbin/setenforce 1'))
  end

  it 'disabled selinux' do
    expect(chef_run).to(
      ChefSpec::Matchers::ResourceMatcher.new(
        :selinux_state, :disabled, 'disabled'))
    expect(chef_run).to(
      ChefSpec::Matchers::ResourceMatcher.new(
        :template, :create, 'disabled selinux config'))
  end

  it 'permissive selinux' do
    expect(chef_run).to(
      ChefSpec::Matchers::ResourceMatcher.new(
        :selinux_state, :permissive, 'permissive'))
    expect(chef_run).to(
      run_execute('selinux-permissive').with_command('/usr/sbin/setenforce 0'))
    expect(chef_run).to(
      render_file('/etc/selinux/config'))
  end
end
