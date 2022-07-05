require 'spec_helper'

describe 'selinux_permissive' do
  step_into :selinux_permissive
  platform 'centos'

  context 'when not set' do
    recipe do
      selinux_permissive 'test' do
        action [:add, :delete]
      end
    end

    stubs_for_provider('selinux_permissive[test]') do |provider|
      allow(provider).to receive_shell_out('semanage permissive -ln', stdout: 'other')
    end

    # this is what actually checks that the fcontext was set correctly
    # incorrect commands would not be stubbed and would throw error
    stubs_for_provider('selinux_permissive[test]') do |provider|
      # when not set, only add calls (-a) should happen
      allow(provider).to receive_shell_out("semanage permissive -a 'test'")
    end

    # needed to have the test run
    it { is_expected.to add_selinux_permissive('test') }
    it { is_expected.to delete_selinux_permissive('test') }
  end

  context 'when set' do
    recipe do
      selinux_permissive 'test' do
        action [:add, :delete]
      end
    end

    stubs_for_provider('selinux_permissive[test]') do |provider|
      allow(provider).to receive_shell_out('semanage permissive -ln', stdout: 'test')
    end

    # this is what actually checks that the fcontext was set correctly
    # incorrect commands would not be stubbed and would throw error
    stubs_for_provider('selinux_permissive[test]') do |provider|
      # when not set, only delete calls (-d) should happen
      allow(provider).to receive_shell_out("semanage permissive -d 'test'")
    end

    # needed to have the test run
    it { is_expected.to add_selinux_permissive('test') }
    it { is_expected.to delete_selinux_permissive('test') }
  end
end
