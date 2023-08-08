require 'spec_helper'

describe 'user' do
  step_into :selinux_user
  platform 'centos'

  recipe do
    selinux_user 'seuser' do
      level 's0'
      range 's0'
      roles %w(staff_r sysadm_r)
      action %i(manage add modify delete)
    end
  end

  context 'when not set' do
    stubs_for_resource('selinux_user[seuser]') do |resource|
      allow(resource).to receive_shell_out('semanage user -l', stdout: '')
    end

    # this is what actually checks that the user was set correctly
    # incorrect commands would not be stubbed and would throw error
    stubs_for_provider('selinux_user[seuser]') do |provider|
      # when not set, only add calls (-a) should happen
      allow(provider).to receive_shell_out("semanage user -a -L s0 -r s0 -R 'staff_r sysadm_r' seuser")
    end

    # needed to have the test run
    it { is_expected.to manage_selinux_user('seuser') }
    it { is_expected.to add_selinux_user('seuser') }
    it { is_expected.to modify_selinux_user('seuser') }
    it { is_expected.to delete_selinux_user('seuser') }
  end

  context 'when set to incorrect value' do
    stubs_for_resource('selinux_user[seuser]') do |resource|
      allow(resource).to receive_shell_out(
        'semanage user -l',
        stdout: <<~STDOUT
                          Labeling   MLS/       MLS/
          SELinux User    Prefix     MCS Level  MCS Range                      SELinux Roles

          guest_u         user       s0         s0                             guest_r
          root            user       s0         s0-s0:c0.c1023                 staff_r sysadm_r system_r unconfined_r
          staff_u         user       s0         s0-s0:c0.c1023                 staff_r sysadm_r system_r unconfined_r
          seuser          user       s0         s0-s0:c0.c1023                 staff_r sysadm_r system_r unconfined_r
          sysadm_u        user       s0         s0-s0:c0.c1023                 sysadm_r
          system_u        user       s0         s0-s0:c0.c1023                 system_r unconfined_r
          unconfined_u    user       s0         s0-s0:c0.c1023                 system_r unconfined_r
          user_u          user       s0         s0                             user_r
          xguest_u        user       s0         s0                             xguest_r
        STDOUT
      )
    end

    # this is what actually checks that the user was set correctly
    # incorrect commands would not be stubbed and would throw error
    stubs_for_provider('selinux_user[seuser]') do |provider|
      # when set incorrectly, only modify calls (-m) and delete calls (-d) should happen
      allow(provider).to receive_shell_out("semanage user -m -L s0 -r s0 -R 'staff_r sysadm_r' seuser")
      allow(provider).to receive_shell_out('semanage user -d seuser')
    end

    # needed to have the test run
    it { is_expected.to manage_selinux_user('seuser') }
    it { is_expected.to add_selinux_user('seuser') }
    it { is_expected.to modify_selinux_user('seuser') }
    it { is_expected.to delete_selinux_user('seuser') }
  end

  context 'when set to correct value' do
    stubs_for_resource('selinux_user[seuser]') do |resource|
      allow(resource).to receive_shell_out(
        'semanage user -l',
        stdout: <<~STDOUT
                          Labeling   MLS/       MLS/
          SELinux User    Prefix     MCS Level  MCS Range                      SELinux Roles

          guest_u         user       s0         s0                             guest_r
          root            user       s0         s0-s0:c0.c1023                 staff_r sysadm_r system_r unconfined_r
          staff_u         user       s0         s0-s0:c0.c1023                 staff_r sysadm_r system_r unconfined_r
          seuser          user       s0         s0                             staff_r sysadm_r
          sysadm_u        user       s0         s0-s0:c0.c1023                 sysadm_r
          system_u        user       s0         s0-s0:c0.c1023                 system_r unconfined_r
          unconfined_u    user       s0         s0-s0:c0.c1023                 system_r unconfined_r
          user_u          user       s0         s0                             user_r
          xguest_u        user       s0         s0                             xguest_r
        STDOUT
      )
    end

    # this is what actually checks that the user was set correctly
    # incorrect commands would not be stubbed and would throw error
    stubs_for_provider('selinux_user[seuser]') do |provider|
      # when set correctly, only delete calls (-d) should happen
      allow(provider).to receive_shell_out('semanage user -d seuser')
    end

    # needed to have the test run
    it { is_expected.to manage_selinux_user('seuser') }
    it { is_expected.to add_selinux_user('seuser') }
    it { is_expected.to modify_selinux_user('seuser') }
    it { is_expected.to delete_selinux_user('seuser') }
  end

  context 'when roles property is unset' do
    recipe do
      selinux_user 'seuser' do
        level 's0'
        range 's0'
        action %i(manage add)
      end
    end

    stubs_for_resource('selinux_user[seuser]') do |resource|
      allow(resource).to receive_shell_out('semanage user -l', stdout: '')
    end

    it 'raises an exception' do
      expect { chef_run }.to raise_error(/roles property must be populated/)
    end
  end
end
