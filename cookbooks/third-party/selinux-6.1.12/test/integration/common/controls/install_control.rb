control 'install' do
  title 'Verify SELinux packages are installed'

  pkgs = if os.debian?
           %w(make policycoreutils selinux-basics selinux-policy-default selinux-policy-dev auditd setools)
         elsif os.name == 'amazon'
           %w(make policycoreutils policycoreutils-python selinux-policy selinux-policy-targeted selinux-policy-devel libselinux-utils setools-console)
         elsif os.redhat?
           case os.release.to_i
           when 6
             %w(make policycoreutils selinux-policy selinux-policy-targeted libselinux-utils setools-console)
           when 7
             %w(make policycoreutils policycoreutils-python selinux-policy selinux-policy-targeted selinux-policy-devel libselinux-utils setools-console)
           else
             %w(make policycoreutils policycoreutils-python-utils selinux-policy selinux-policy-targeted selinux-policy-devel libselinux-utils setools-console)
           end
         else
           %w(make policycoreutils policycoreutils-python-utils selinux-policy selinux-policy-targeted selinux-policy-devel libselinux-utils setools-console)
         end

  pkgs.each do |pkg|
    describe package(pkg) do
      it { should be_installed }
    end
  end
end
