require 'spec_helper'

describe 'selinux_boolean' do
  step_into :selinux_boolean
  platform 'centos'

  stubs_for_provider('selinux_boolean[test]') do |provider|
    allow(provider).to receive_shell_out('getenforce', stdout: 'Permissive')
  end

  context 'when boolean is set to incorrect value' do
    recipe do
      selinux_boolean 'test' do
        value 'on'
      end
    end

    stubs_for_resource('selinux_boolean[test]') do |resource|
      allow(resource).to receive_shell_out('getsebool test', stdout: 'off')
    end

    # this is what actually checks that the bool was set correctly
    # incorrect commands would not be stubbed and would throw error
    stubs_for_provider('selinux_boolean[test]') do |provider|
      allow(provider).to receive_shell_out('setsebool -P test on')
    end

    # needed to have the test run
    it { is_expected.to set_selinux_boolean('test') }
  end

  context 'when boolean is set to correct value' do
    recipe do
      selinux_boolean 'test' do
        value 'on'
      end
    end

    stubs_for_resource('selinux_boolean[test]') do |resource|
      allow(resource).to receive_shell_out('getsebool test', stdout: 'on')
    end

    # dont stub the set command since the resource should not actually
    # shell out for it since it is already set to the correct value
    # stubs_for_provider("selinux_boolean[test]") do |provider|
    #   allow(provider).to receive_shell_out('setsebool -P test on')
    # end

    # needed to have the test run
    it { is_expected.to set_selinux_boolean('test') }
  end
end
