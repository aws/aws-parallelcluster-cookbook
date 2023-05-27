class NilClass
  def blank?
    true
  end
end

class String
  def blank?
    strip.empty?
  end
end

#
# Check if a service is installed in the instance and in the specific platform
#
def is_service_installed?(service, platform_families = node['platform_family'])
  if platform_family?(platform_families)
    # Add chkconfig for alinux2 and centos platform, because they do not generate systemd unit file automatically from init script
    # Ubuntu platform generate systemd unit file from init script automatically, if the service is not found by systemd the check will fail because chkconfig does not exist
    Mixlib::ShellOut.new("systemctl daemon-reload; systemctl list-unit-files --all | grep #{service} || chkconfig --list #{service}").run_command.exitstatus.to_i.zero?
  else
    # in case of different platform return false
    false
  end
end
