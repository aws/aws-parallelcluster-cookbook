module SELinux
  module Cookbook
    module StateHelpers
      def selinux_disabled?
        selinux_state.eql?(:disabled)
      end

      def selinux_enforcing?
        selinux_state.eql?(:enforcing)
      end

      def selinux_permissive?
        selinux_state.eql?(:permissive)
      end

      def state_change_reboot_required?
        (selinux_disabled? && %i(enforcing permissive).include?(action)) ||
          ((selinux_enforcing? || selinux_permissive?) && action == :disabled) ||
          (selinux_activate_required? && %i(enforcing permissive).include?(action))
      end

      def selinux_state
        state = shell_out!('getenforce').stdout.strip.downcase.to_sym
        raise "Got unknown SELinux state #{state}" unless %i(disabled enforcing permissive).include?(state)

        state
      end

      def selinux_activate_required?
        return false unless platform_family?('debian')
        sestatus = shell_out!('sestatus -v').stdout.strip

        # Ensure we're booted up to a system which has selinux activated and filesystem is properly labeled
        if File.read('/proc/cmdline').match?('security=selinux') && sestatus.match?(%r{/usr/sbin/sshd.*sshd_exec_t})
          false
        else
          true
        end
      end

      def selinux_activate_cmd
        # selinux-activate is semi-broken on Ubuntu 18.04 however this method does work
        if platform?('ubuntu') && node['platform_version'] == '18.04'
          'touch /.autorelabel'
        else
          '/usr/sbin/selinux-activate'
        end
      end

      def default_policy_platform
        case node['platform_family']
        when 'rhel', 'fedora', 'amazon'
          'targeted'
        when 'debian'
          'default'
        end
      end
    end
  end
end
