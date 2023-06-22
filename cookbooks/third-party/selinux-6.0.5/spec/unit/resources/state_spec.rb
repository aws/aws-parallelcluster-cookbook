require 'spec_helper'

describe 'selinux_state' do
  step_into :selinux_state
  platform 'centos'

  context 'selinux state disable' do
    recipe do
      selinux_state 'disabled' do
        action :disabled
      end
    end

    stubs_for_provider('selinux_state[disabled]') do |provider|
      allow(provider).to receive_shell_out('getenforce', stdout: 'Disabled')
    end

    it 'Creates the selinux config file correctly' do
      is_expected.to render_file('/etc/selinux/config')
        .with_content(/SELINUX=disabled/)
    end
  end

  context 'selinux state permissive' do
    recipe do
      selinux_state 'permissive' do
        action :permissive
      end
    end

    stubs_for_provider('selinux_state[permissive]') do |provider|
      allow(provider).to receive_shell_out('getenforce', stdout: 'Permissive')
    end

    it 'Creates the selinux config file correctly' do
      is_expected.to render_file('/etc/selinux/config')
        .with_content(/SELINUX=permissive/)
    end
  end

  context 'selinux state enforcing' do
    recipe do
      selinux_state 'enforcing' do
        action :enforcing
      end
    end

    stubs_for_provider('selinux_state[enforcing]') do |provider|
      allow(provider).to receive_shell_out('getenforce', stdout: 'Enforcing')
    end

    it 'Creates the selinux config file correctly' do
      is_expected.to render_file('/etc/selinux/config')
        .with_content(/SELINUX=enforcing/)
    end
  end
end
