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
        (selinux_disabled? && %i(enforcing permissive).include?(action)) || ((selinux_enforcing? || selinux_permissive?) && action == :disabled)
      end

      def selinux_state
        state = shell_out!('getenforce').stdout.strip.downcase.to_sym
        raise "Got unknown SELinux state #{state}" unless %i(disabled enforcing permissive).include?(state)

        state
      end

      def selinux_activate_required?
        return false unless platform_family?('debian')

        !File.read('/etc/default/grub').match?('security=selinux')
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
