require 'spec_helper'

class ConvergeCStates
  def self.setup(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-platform') do
      c_states 'setup' do
        action :setup
      end
    end
  end
end

describe 'c_states:setup' do
  before do
    stubs_for_resource('c_states') do |res|
      allow(res).to receive(:append_if_not_present_grub_cmdline)
    end
  end

  for_all_oses do |platform, version|
    context "on #{platform}#{version} x86" do
      cached(:chef_run) do
        runner = ChefSpec::Runner.new(
          platform: platform, version: version,
          step_into: ['c_states']
        ) do |node|
          node.automatic['kernel']['machine'] = 'x86_64'
        end
        ConvergeCStates.setup(runner)
      end
      cached(:grub_cmdline_attributes) do
        {
          "intel_idle.max_cstate" => { "value" => "1" },
          "processor.max_cstate" => { "value" => "1" },
        }
      end
      cached(:grub_variable) { platform == 'ubuntu' ? 'GRUB_CMDLINE_LINUX' : 'GRUB_CMDLINE_LINUX_DEFAULT' }
      cached(:regenerate_grub_boot_menu_command) do
        platform == 'ubuntu' ? '/usr/sbin/update-grub' : '/usr/sbin/grub2-mkconfig -o /boot/grub2/grub.cfg'
      end

      it 'sets up c_states' do
        is_expected.to setup_c_states('setup')
      end

      it 'edits /etc/default/grub' do
        stubs_for_resource('c_states[setup]') do |res|
          expect(res).to receive(:append_if_not_present_grub_cmdline).with(grub_cmdline_attributes, grub_variable)
        end
        chef_run
      end

      it 'regenerate grub boot menus' do
        is_expected.to run_execute('Regenerate grub boot menu')
          .with(command: regenerate_grub_boot_menu_command)
      end
    end

    context "on #{platform}#{version} arm" do
      cached(:chef_run) do
        runner = ChefSpec::Runner.new(
          platform: platform, version: version,
          step_into: ['c_states']
        ) do |node|
          node.automatic['kernel']['machine'] = 'aarch64'
        end
        ConvergeCStates.setup(runner)
      end

      it 'does not edit /etc/default/grub' do
        stubs_for_resource('c_states[setup]') do |res|
          expect(res).not_to receive(:append_if_not_present_grub_cmdline)
        end
        chef_run
      end

      it 'does not regenerate grub boot menus' do
        is_expected.not_to run_execute('Regenerate grub boot menu')
      end
    end
  end
end
