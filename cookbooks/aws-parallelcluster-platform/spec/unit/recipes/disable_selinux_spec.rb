require 'spec_helper'

describe 'aws-parallelcluster-platform::disable_selinux' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        # Stub guards so ChefSpec doesn't shell out during converge.
        stub_command('which getenforce').and_return('/usr/sbin/getenforce')
        stub_command('grubby --info=ALL | grep -q "selinux=0"').and_return(false)
        stub_command('grep -qE "^GRUB_CMDLINE_LINUX(_DEFAULT)?=.*selinux=1" /etc/default/grub').and_return(true)
        stub_command('grep -qE "^GRUB_CMDLINE_LINUX(_DEFAULT)?=.*selinux=" /etc/default/grub').and_return(false)
        # The recipe early-returns on Docker; force false to exercise the real branch.
        allow_any_instance_of(Chef::Recipe).to receive(:on_docker?).and_return(false)

        ChefSpec::Runner.new(platform: platform, version: version).converge(described_recipe)
      end

      if platform == 'ubuntu'
        it 'is a no-op on Debian-family OSes' do
          is_expected.not_to disabled_selinux_state('SELinux Disabled')
          is_expected.not_to run_execute('disable selinux via grubby')
          is_expected.not_to run_execute('replace selinux=1 in /etc/default/grub')
          is_expected.not_to run_execute('append selinux=0 to /etc/default/grub')
        end
      else
        it 'disables SELinux via the selinux_state resource' do
          is_expected.to disabled_selinux_state('SELinux Disabled')
        end

        it 'disables SELinux via grubby' do
          is_expected.to run_execute('disable selinux via grubby')
            .with_command('grubby --update-kernel=ALL --args="selinux=0"')
        end

        it 'replaces selinux=1 in /etc/default/grub' do
          is_expected.to run_execute('replace selinux=1 in /etc/default/grub')
            .with_command(%q(sed -i -E '/^GRUB_CMDLINE_LINUX(_DEFAULT)?=/ s/selinux=1/selinux=0/g' /etc/default/grub))
        end

        it 'appends selinux=0 to /etc/default/grub' do
          is_expected.to run_execute('append selinux=0 to /etc/default/grub')
            .with_command(%q(sed -i -E '/^GRUB_CMDLINE_LINUX(_DEFAULT)?=/ {/selinux=/!s/"$/ selinux=0"/}' /etc/default/grub))
        end
      end
    end
  end
end
