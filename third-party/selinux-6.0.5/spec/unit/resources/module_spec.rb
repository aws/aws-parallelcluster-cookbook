require 'spec_helper'

describe 'selinux_module' do
  step_into :selinux_module
  platform 'centos'

  before do
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(%r{/etc/selinux/local/.+.pp}).and_return(true)
  end

  context 'create from content' do
    recipe do
      selinux_module 'test_content' do
        content 'some content for the module'
      end
    end

    it do
      is_expected.to create_file('/etc/selinux/local/test_content.te').with(
        content: 'some content for the module'
      )
    end

    it do
      expect(chef_run.file('/etc/selinux/local/test_content.te')).to \
        notify("execute[Compiling SELinux modules at '/etc/selinux/local']").to(:run).immediately
    end

    it do
      is_expected.to nothing_execute("Compiling SELinux modules at '/etc/selinux/local'").with(
        cwd: '/etc/selinux/local',
        command: 'make -C /etc/selinux/local -f /usr/share/selinux/devel/Makefile'
      )
    end

    it do
      expect(chef_run.execute("Compiling SELinux modules at '/etc/selinux/local'")).to \
        notify("execute[Install SELinux module '/etc/selinux/local/test_content.pp']").to(:run).immediately
    end

    it do
      is_expected.to nothing_execute("Install SELinux module '/etc/selinux/local/test_content.pp'").with(
        command: "semodule --install '/etc/selinux/local/test_content.pp'"
      )
    end
  end

  context 'create from file' do
    recipe do
      selinux_module 'test_file' do
        source 'a_test_file.te'
        cookbook 'foo'
      end
    end

    it do
      is_expected.to create_cookbook_file('/etc/selinux/local/test_file.te').with(
        source: 'a_test_file.te',
        cookbook: 'foo'
      )
    end

    it do
      expect(chef_run.cookbook_file('/etc/selinux/local/test_file.te')).to \
        notify("execute[Compiling SELinux modules at '/etc/selinux/local']").to(:run).immediately
    end

    it do
      is_expected.to nothing_execute("Compiling SELinux modules at '/etc/selinux/local'").with(
        cwd: '/etc/selinux/local',
        command: 'make -C /etc/selinux/local -f /usr/share/selinux/devel/Makefile'
      )
    end

    it do
      expect(chef_run.execute("Compiling SELinux modules at '/etc/selinux/local'")).to \
        notify("execute[Install SELinux module '/etc/selinux/local/test_file.pp']").to(:run).immediately
    end

    it do
      is_expected.to nothing_execute("Install SELinux module '/etc/selinux/local/test_file.pp'").with(
        command: "semodule --install '/etc/selinux/local/test_file.pp'"
      )
    end
  end

  context 'delete' do
    before do
      allow(File).to receive(:exist?).with(%r{/etc/selinux/local/test.+}).and_return(true)
    end

    recipe do
      selinux_module 'test' do
        action :delete
      end
    end

    it { is_expected.to delete_file('/etc/selinux/local/test.fc') }
    it { is_expected.to delete_file('/etc/selinux/local/test.if') }
    it { is_expected.to delete_file('/etc/selinux/local/test.pp') }
    it { is_expected.to delete_file('/etc/selinux/local/test.te') }
  end

  context 'install' do
    recipe do
      selinux_module 'installed' do
        action :install
      end

      selinux_module 'gone' do
        action :install
      end
    end

    stubs_for_provider('selinux_module[installed]') do |provider|
      allow(provider).to receive_shell_out('semodule --list-modules', stdout: 'installed')
    end

    stubs_for_provider('selinux_module[gone]') do |provider|
      allow(provider).to receive_shell_out('semodule --list-modules', stdout: 'other')
      allow(provider).to receive_shell_out('semodule --install \'/etc/selinux/local/gone.pp\'')
    end

    it { is_expected.to install_selinux_module('installed') }
    it { is_expected.to install_selinux_module('gone') }
  end

  context 'remove' do
    recipe do
      selinux_module 'installed' do
        action :remove
      end

      selinux_module 'gone' do
        action :remove
      end
    end

    stubs_for_provider('selinux_module[installed]') do |provider|
      allow(provider).to receive_shell_out('semodule --list-modules', stdout: 'installed')
      allow(provider).to receive_shell_out('semodule --remove \'installed\'')
    end

    stubs_for_provider('selinux_module[gone]') do |provider|
      allow(provider).to receive_shell_out('semodule --list-modules', stdout: 'other')
    end

    it { is_expected.to remove_selinux_module('installed') }
    it { is_expected.to remove_selinux_module('gone') }
  end
end
