require 'spec_helper'

describe 'selinux_port' do
  step_into :selinux_port
  platform 'centos'

  stubs_for_provider('selinux_port[1234]') do |provider|
    allow(provider).to receive_shell_out('getenforce', stdout: 'Permissive')
  end

  recipe do
    selinux_port '1234' do
      protocol 'tcp'
      secontext 'test_t'
      action %i(manage add modify delete)
    end
  end

  context 'when not set' do
    stubs_for_provider('selinux_port[1234]') do |provider|
      allow(provider).to receive_shell_out(<<~CMD, stdout: '')
        seinfo --portcon=1234 | grep 'portcon tcp' | \
        awk -F: '$(NF-1) !~ /reserved_port_t$/ && $(NF-3) !~ /[0-9]*-[0-9]*/ {print $(NF-1)}'
      CMD
    end

    # this is what actually checks that the port was set correctly
    # incorrect commands would not be stubbed and would throw error
    stubs_for_provider('selinux_port[1234]') do |provider|
      # when not set, only add calls (-a) should happen
      allow(provider).to receive_shell_out("semanage port -a -t 'test_t' -p tcp 1234")
    end

    # needed to have the test run
    it { is_expected.to manage_selinux_port('1234') }
    it { is_expected.to add_selinux_port('1234') }
    it { is_expected.to modify_selinux_port('1234') }
    it { is_expected.to delete_selinux_port('1234') }
  end

  context 'when set to incorrect value' do
    stubs_for_provider('selinux_port[1234]') do |provider|
      allow(provider).to receive_shell_out(<<~CMD, stdout: 'other_t')
        seinfo --portcon=1234 | grep 'portcon tcp' | \
        awk -F: '$(NF-1) !~ /reserved_port_t$/ && $(NF-3) !~ /[0-9]*-[0-9]*/ {print $(NF-1)}'
      CMD
    end

    # this is what actually checks that the port was set correctly
    # incorrect commands would not be stubbed and would throw error
    stubs_for_provider('selinux_port[1234]') do |provider|
      # when set incorrectly, only modify calls (-m) and delete calls (-d) should happen
      allow(provider).to receive_shell_out("semanage port -m -t 'test_t' -p tcp 1234")
      allow(provider).to receive_shell_out('semanage port -d -p tcp 1234')
    end

    # needed to have the test run
    it { is_expected.to manage_selinux_port('1234') }
    it { is_expected.to add_selinux_port('1234') }
    it { is_expected.to modify_selinux_port('1234') }
    it { is_expected.to delete_selinux_port('1234') }
  end

  context 'when set to correct value' do
    stubs_for_provider('selinux_port[1234]') do |provider|
      allow(provider).to receive_shell_out(<<~CMD, stdout: 'test_t')
        seinfo --portcon=1234 | grep 'portcon tcp' | \
        awk -F: '$(NF-1) !~ /reserved_port_t$/ && $(NF-3) !~ /[0-9]*-[0-9]*/ {print $(NF-1)}'
      CMD
    end

    # this is what actually checks that the port was set correctly
    # incorrect commands would not be stubbed and would throw error
    stubs_for_provider('selinux_port[1234]') do |provider|
      # when set correctly, only delete calls (-d) should happen
      allow(provider).to receive_shell_out('semanage port -d -p tcp 1234')
    end

    # needed to have the test run
    it { is_expected.to manage_selinux_port('1234') }
    it { is_expected.to add_selinux_port('1234') }
    it { is_expected.to modify_selinux_port('1234') }
    it { is_expected.to delete_selinux_port('1234') }
  end

  context 'when port has multiple contexts' do
    stubs_for_provider('selinux_port[1234]') do |provider|
      allow(provider).to receive_shell_out(<<~CMD, stdout: "test_t\nother_t")
        seinfo --portcon=1234 | grep 'portcon tcp' | \
        awk -F: '$(NF-1) !~ /reserved_port_t$/ && $(NF-3) !~ /[0-9]*-[0-9]*/ {print $(NF-1)}'
      CMD
    end

    # this is what actually checks that the port was set correctly
    # incorrect commands would not be stubbed and would throw error
    stubs_for_provider('selinux_port[1234]') do |provider|
      # when set correctly, only delete calls (-d) should happen
      allow(provider).to receive_shell_out('semanage port -d -p tcp 1234')
    end

    # needed to have the test run
    it { is_expected.to manage_selinux_port('1234') }
    it { is_expected.to add_selinux_port('1234') }
    it { is_expected.to modify_selinux_port('1234') }
    it { is_expected.to delete_selinux_port('1234') }
  end
end
