require 'spec_helper'

describe 'login' do
  step_into :selinux_login
  platform 'centos'

  recipe do
    selinux_login 'oslogin' do
      user 'seuser'
      range 's0'
      action %i(manage add modify delete)
    end
  end

  context 'when not set' do
    stubs_for_resource('selinux_login[oslogin]') do |resource|
      allow(resource).to receive_shell_out('semanage login -l', stdout: '')
    end

    # this is what actually checks that the login was set correctly
    # incorrect commands would not be stubbed and would throw error
    stubs_for_provider('selinux_login[oslogin]') do |provider|
      # when not set, only add calls (-a) should happen
      allow(provider).to receive_shell_out('semanage login -a -s seuser -r s0 oslogin')
    end

    # needed to have the test run
    it { is_expected.to manage_selinux_login('oslogin') }
    it { is_expected.to add_selinux_login('oslogin') }
    it { is_expected.to modify_selinux_login('oslogin') }
    it { is_expected.to delete_selinux_login('oslogin') }
  end

  context 'when set to incorrect value' do
    stubs_for_resource('selinux_login[oslogin]') do |resource|
      allow(resource).to receive_shell_out(
        'semanage login -l',
        stdout: <<~STDOUT
          Login Name           SELinux User         MLS/MCS Range        Service

          __default__          unconfined_u         s0-s0:c0.c1023       *
          root                 unconfined_u         s0-s0:c0.c1023       *
          oslogin              unconfined_u         s0-s0:c0.c1023       *
        STDOUT
      )
    end

    # this is what actually checks that the login was set correctly
    # incorrect commands would not be stubbed and would throw error
    stubs_for_provider('selinux_login[oslogin]') do |provider|
      # when set incorrectly, only modify calls (-m) and delete calls (-d) should happen
      allow(provider).to receive_shell_out('semanage login -m -s seuser -r s0 oslogin')
      allow(provider).to receive_shell_out('semanage login -d oslogin')
    end

    # needed to have the test run
    it { is_expected.to manage_selinux_login('oslogin') }
    it { is_expected.to add_selinux_login('oslogin') }
    it { is_expected.to modify_selinux_login('oslogin') }
    it { is_expected.to delete_selinux_login('oslogin') }
  end

  context 'when set to correct value' do
    stubs_for_resource('selinux_login[oslogin]') do |resource|
      allow(resource).to receive_shell_out(
        'semanage login -l',
        stdout: <<~STDOUT
          Login Name           SELinux User         MLS/MCS Range        Service

          __default__          unconfined_u         s0-s0:c0.c1023       *
          root                 unconfined_u         s0-s0:c0.c1023       *
          oslogin              seuser               s0                   *
        STDOUT
      )
    end

    # this is what actually checks that the login was set correctly
    # incorrect commands would not be stubbed and would throw error
    stubs_for_provider('selinux_login[oslogin]') do |provider|
      # when set correctly, only delete calls (-d) should happen
      allow(provider).to receive_shell_out('semanage login -d oslogin')
    end

    # needed to have the test run
    it { is_expected.to manage_selinux_login('oslogin') }
    it { is_expected.to add_selinux_login('oslogin') }
    it { is_expected.to modify_selinux_login('oslogin') }
    it { is_expected.to delete_selinux_login('oslogin') }
  end

  context 'when user property is unset' do
    recipe do
      selinux_login 'oslogin' do
        range 's0'
        action %i(manage add)
      end
    end

    stubs_for_resource('selinux_login[oslogin]') do |resource|
      allow(resource).to receive_shell_out('semanage login -l', stdout: '')
    end

    it 'raises an exception' do
      expect { chef_run }.to raise_error(/user property must be populated/)
    end
  end
end
