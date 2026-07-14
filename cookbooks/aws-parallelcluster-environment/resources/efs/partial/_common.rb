unified_mode true

default_action :install_utils

def _efs_utils_version
  node['cluster']['efs']['version']
end

# Tracked major line; the repo installs the newest release below the next major
# (EFS guarantees no breaking changes within a major).
def _efs_utils_major
  _efs_utils_version.split('.').first.to_i
end

# Public EFS package endpoint (CloudFront).
def efs_domain
  "https://amazon-efs-utils.aws.com"
end

# DevSetting: skip the efs-utils install.
def _skip_efs_utils_install?
  node['cluster']['efs']['skip_install'].to_s == 'true'
end

# If efs-utils is already on the AMI, treat it as CX-owned and don't override,
# regardless of version. Probe the mount.efs binary it provides (Package Manager
# agnostic and stable); it resolves to /usr/sbin on all supported OSes.
def already_installed?
  ::File.exist?('/usr/sbin/mount.efs')
end

action :increase_poll_interval do
  # An interval too short could affect HPC workload performance
  replace_or_add "increase EFS-utils watchdog poll interval" do
    path "/etc/amazon/efs/efs-utils.conf"
    pattern "poll_interval_sec = 1$"
    line "poll_interval_sec = 10"
    replace_only true
  end
end

action :install_efs_utils_within_major do
  # `package` can't express a version range, so cap the major via dnf.
  execute "install amazon-efs-utils" do
    command "dnf install -y 'amazon-efs-utils < #{_efs_utils_major + 1}'"
    retries 3
    retry_delay 5
  end
end
