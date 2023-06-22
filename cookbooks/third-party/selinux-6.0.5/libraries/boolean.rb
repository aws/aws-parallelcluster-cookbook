module SELinux
  module Cookbook
    module BooleanHelpers
      def selinux_bool(bool)
        if ['on', 'true', '1', true, 1].include?(bool)
          'on'
        elsif ['off', 'false', '0', false, 0].include?(bool)
          'off'
        else
          raise ArgumentError, "selinux_bool: Invalid selinux boolean value #{bool}"
        end
      end

      module_function :selinux_bool
    end
  end
end
