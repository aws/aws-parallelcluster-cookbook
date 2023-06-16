require 'spec_helper'

describe 'selinux_fcontext' do
  step_into :selinux_fcontext
  platform 'centos'

  stubs_for_provider('selinux_fcontext[/test]') do |provider|
    allow(provider).to receive_shell_out('getenforce', stdout: 'Permissive')
  end

  recipe do
    selinux_fcontext '/test' do
      secontext 'foo'
      action %i(manage add modify delete)
    end
  end

  context 'when not set' do
    stubs_for_provider('selinux_fcontext[/test]') do |provider|
      allow(provider).to receive_shell_out('semanage fcontext -l', stdout: <<~EOF)
        /other/files        all files        user:role:type:level
      EOF
    end

    # this is what actually checks that the fcontext was set correctly
    # incorrect commands would not be stubbed and would throw error
    stubs_for_provider('selinux_fcontext[/test]') do |provider|
      # when not set, only add calls (-a) should happen
      allow(provider).to receive_shell_out("semanage fcontext -a -f a -t foo '/test'")
    end

    # needed to have the test run
    it { is_expected.to manage_selinux_fcontext('/test') }
    it { is_expected.to add_selinux_fcontext('/test') }
    it { is_expected.to modify_selinux_fcontext('/test') }
    it { is_expected.to delete_selinux_fcontext('/test') }
  end

  context 'when set to incorrect value' do
    stubs_for_provider('selinux_fcontext[/test]') do |provider|
      allow(provider).to receive_shell_out('semanage fcontext -l', stdout: <<~EOF)
        /test        all files        user:role:type:level
      EOF
    end

    # this is what actually checks that the fcontext was set correctly
    # incorrect commands would not be stubbed and would throw error
    stubs_for_provider('selinux_fcontext[/test]') do |provider|
      # when set but incorrect, only modify calls (-m) and delete calls (-d) should happen
      allow(provider).to receive_shell_out("semanage fcontext -m -f a -t foo '/test'")
      allow(provider).to receive_shell_out("semanage fcontext -d -f a '/test'")
    end

    # needed to have the test run
    it { is_expected.to manage_selinux_fcontext('/test') }
    it { is_expected.to add_selinux_fcontext('/test') }
    it { is_expected.to modify_selinux_fcontext('/test') }
    it { is_expected.to delete_selinux_fcontext('/test') }
  end

  context 'when set to correct value' do
    stubs_for_provider('selinux_fcontext[/test]') do |provider|
      allow(provider).to receive_shell_out('semanage fcontext -l', stdout: <<~EOF)
        /test        all files        user:role:foo:level
      EOF
    end

    # this is what actually checks that the fcontext was set correctly
    # incorrect commands would not be stubbed and would throw error
    stubs_for_provider('selinux_fcontext[/test]') do |provider|
      # when set correctly, only delete calls (-d) should happen
      allow(provider).to receive_shell_out("semanage fcontext -d -f a '/test'")
    end

    # needed to have the test run
    it { is_expected.to manage_selinux_fcontext('/test') }
    it { is_expected.to add_selinux_fcontext('/test') }
    it { is_expected.to modify_selinux_fcontext('/test') }
    it { is_expected.to delete_selinux_fcontext('/test') }
  end
end
