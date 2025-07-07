require 'spec_helper'

describe 'dnf_module' do
  platform 'centos', '8'
  step_into :dnf_module

  installed_enabled = <<~EOF
    Name           Stream           Profiles                Summary
    test           1.0 [d][e]       common [d] [i]          Just a testing module
    Hint: [d]efault, [e]nabled, [x]disabled, [i]nstalled
  EOF

  removed_disabled = <<~EOF
    Name           Stream           Profiles                Summary
    test           1.0 [d][x]       common [d]              Just a testing module
    Hint: [d]efault, [e]nabled, [x]disabled, [i]nstalled
  EOF

  other_version = <<~EOF
    Name           Stream           Profiles                Summary
    test           0.5 [e]          common [i]              Just a testing module
    test           1.0 [d]          common [d]              Just a testing module
    Hint: [d]efault, [e]nabled, [x]disabled, [i]nstalled
 EOF

  context 'install' do
    recipe do
      dnf_module 'test:1.0' do
        options '--option'
        action :install
      end
    end

    context 'when module is not installed' do
      stubs_for_provider('dnf_module[test:1.0]') do |provider|
        allow(provider).to receive_shell_out('dnf -q module list', stdout: removed_disabled)
        # this is what actually checks the correct command was run
        # incorrect commands would not be stubbed and would throw error
        allow(provider).to receive_shell_out("dnf -qy module install --option 'test:1.0'")
      end

      # needed for test to run
      it { is_expected.to install_dnf_module('test:1.0') }

      # test once here, works the same for all the other actions
      it { is_expected.to flush_cache_package('flush package cache test:1.0') }
    end

    context 'when module is already installed' do
      stubs_for_provider('dnf_module[test:1.0]') do |provider|
        allow(provider).to receive_shell_out('dnf -q module list', stdout: installed_enabled)
        # install command should not be executed here so don't stub
      end

      it { is_expected.to install_dnf_module('test:1.0') }
    end
  end

  context 'remove' do
    recipe do
      dnf_module 'test:1.0' do
        options '--option'
        action :remove
      end
    end

    context 'when module is not installed' do
      stubs_for_provider('dnf_module[test:1.0]') do |provider|
        allow(provider).to receive_shell_out('dnf -q module list', stdout: removed_disabled)
        # remove command should not be executed here so don't stub
      end

      it { is_expected.to remove_dnf_module('test:1.0') }
    end

    context 'when module is already installed' do
      stubs_for_provider('dnf_module[test:1.0]') do |provider|
        allow(provider).to receive_shell_out('dnf -q module list', stdout: installed_enabled)
        allow(provider).to receive_shell_out("dnf -qy module remove --option 'test:1.0'")
      end

      it { is_expected.to remove_dnf_module('test:1.0') }
    end
  end

  context 'enable' do
    recipe do
      dnf_module 'test:1.0' do
        options '--option'
        action :enable
      end
    end

    context 'when module is not enabled' do
      stubs_for_provider('dnf_module[test:1.0]') do |provider|
        allow(provider).to receive_shell_out('dnf -q module list', stdout: removed_disabled)
        allow(provider).to receive_shell_out("dnf -qy module enable --option 'test:1.0'")
      end

      it { is_expected.to enable_dnf_module('test:1.0') }
    end

    context 'when module is already enabled' do
      stubs_for_provider('dnf_module[test:1.0]') do |provider|
        allow(provider).to receive_shell_out('dnf -q module list', stdout: installed_enabled)
        # enable command should not be executed here so don't stub
      end

      it { is_expected.to enable_dnf_module('test:1.0') }
    end
  end

  context 'disable' do
    recipe do
      dnf_module 'test:1.0' do
        options '--option'
        action :disable
      end
    end

    context 'when module is already disabled' do
      stubs_for_provider('dnf_module[test:1.0]') do |provider|
        allow(provider).to receive_shell_out('dnf -q module list', stdout: removed_disabled)
        # disable command should not be executed here so don't stub
      end

      it { is_expected.to disable_dnf_module('test:1.0') }
    end

    context 'when module is not disabled' do
      stubs_for_provider('dnf_module[test:1.0]') do |provider|
        allow(provider).to receive_shell_out('dnf -q module list', stdout: installed_enabled)
        allow(provider).to receive_shell_out("dnf -qy module disable --option 'test:1.0'")
      end

      it { is_expected.to disable_dnf_module('test:1.0') }
    end
  end

  context 'switch_to' do
    recipe do
      dnf_module 'test:1.0' do
        options '--option'
        action :switch_to
      end
    end

    context 'when module is not enabled' do
      stubs_for_provider('dnf_module[test:1.0]') do |provider|
        allow(provider).to receive_shell_out('dnf -q module list', stdout: removed_disabled)
        allow(provider).to receive_shell_out("dnf -qy module switch-to --option 'test:1.0'")
      end

      it { is_expected.to switch_to_dnf_module('test:1.0') }
    end

    context 'when module is already enabled' do
      stubs_for_provider('dnf_module[test:1.0]') do |provider|
        allow(provider).to receive_shell_out('dnf -q module list', stdout: installed_enabled)
        # switch command should not be executed here so don't stub
      end

      it { is_expected.to switch_to_dnf_module('test:1.0') }
    end

    context 'when module is at different version' do
      stubs_for_provider('dnf_module[test:1.0]') do |provider|
        allow(provider).to receive_shell_out('dnf -q module list', stdout: other_version)
        allow(provider).to receive_shell_out("dnf -qy module switch-to --option 'test:1.0'")
      end

      it { is_expected.to switch_to_dnf_module('test:1.0') }
    end
  end

  context 'reset' do
    recipe do
      dnf_module 'test:1.0' do
        options '--option'
        action :reset
      end
    end

    context 'when module is not enabled' do
      stubs_for_provider('dnf_module[test:1.0]') do |provider|
        allow(provider).to receive_shell_out('dnf -q module list', stdout: removed_disabled)
        allow(provider).to receive_shell_out("dnf -qy module reset --option 'test:1.0'")
      end

      it { is_expected.to reset_dnf_module('test:1.0') }
    end

    context 'when module is already enabled' do
      stubs_for_provider('dnf_module[test:1.0]') do |provider|
        allow(provider).to receive_shell_out('dnf -q module list', stdout: installed_enabled)
        allow(provider).to receive_shell_out("dnf -qy module reset --option 'test:1.0'")
      end

      it { is_expected.to reset_dnf_module('test:1.0') }
    end
  end

  context 'no cache flush' do
    recipe do
      dnf_module 'test:1.0' do
        flush_cache false
        action :install
      end
    end

    stubs_for_provider('dnf_module[test:1.0]') do |provider|
      allow(provider).to receive_shell_out('dnf -q module list', stdout: removed_disabled)
      allow(provider).to receive_shell_out("dnf -qy module install  'test:1.0'")
    end

    it { is_expected.to_not flush_cache_package('flush package cache test:1.0') }
  end

  context 'noop on C7' do
    platform 'centos', '7'

    recipe do
      dnf_module 'test:1.0' do
        action :install
      end
    end

    stubs_for_provider('dnf_module[test:1.0]') do |provider|
      # no commands should be run since the resource immediately returns
    end

    # needed for test to run
    it { is_expected.to install_dnf_module('test:1.0') }
  end
end
