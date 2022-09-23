module SELinux
  module Cookbook
    module InstallHelpers
      def default_install_packages
        case node['platform_family']
        when 'rhel', 'fedora', 'amazon'
          %w(make policycoreutils selinux-policy selinux-policy-targeted selinux-policy-devel libselinux-utils setools-console)
        when 'debian'
          if node['platform'] == 'ubuntu'
            if node['platform_version'].to_f == 18.04
              %w(make policycoreutils selinux selinux-basics selinux-policy-default selinux-policy-dev auditd setools)
            else
              %w(make policycoreutils selinux-basics selinux-policy-default selinux-policy-dev auditd setools)
            end
          else
            %w(make policycoreutils selinux-basics selinux-policy-default selinux-policy-dev auditd setools)
          end
        end
      end
    end
  end
end
