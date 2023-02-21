# aws-parallelcluster-install attributes

# Default gc_thresh values for performance at scale
default['cluster']['sysctl']['ipv4']['gc_thresh1'] = 0
default['cluster']['sysctl']['ipv4']['gc_thresh2'] = 15_360
default['cluster']['sysctl']['ipv4']['gc_thresh3'] = 16_384

# Lustre defaults (for CentOS >=7.7 and Ubuntu)
default['cluster']['lustre']['public_key'] = value_for_platform(
  'centos' => { '>=7.7' => "https://fsx-lustre-client-repo-public-keys.s3.amazonaws.com/fsx-rpm-public-key.asc" },
  'redhat' => { 'default' => "https://fsx-lustre-client-repo-public-keys.s3.amazonaws.com/fsx-rpm-public-key.asc" },
  'ubuntu' => { 'default' => "https://fsx-lustre-client-repo-public-keys.s3.amazonaws.com/fsx-ubuntu-public-key.asc" }
)
# Lustre repo string is built following the official doc
# https://docs.aws.amazon.com/fsx/latest/LustreGuide/install-lustre-client.html
# 'centos' is used for arm and 'el' for x86_64
default['cluster']['lustre']['centos7']['base_url_prefix'] = arm_instance? ? 'centos' : 'el'
default['cluster']['lustre']['base_url'] = value_for_platform(
  'centos' => {
    # node['kernel']['machine'] contains the architecture: 'x86_64' or 'aarch64'
    'default' => "https://fsx-lustre-client-repo.s3.amazonaws.com/#{default['cluster']['lustre']['centos7']['base_url_prefix']}/7.#{find_centos_minor_version}/#{node['kernel']['machine']}/",
  },
  'ubuntu' => { 'default' => "https://fsx-lustre-client-repo.s3.amazonaws.com/ubuntu" },
  'redhat' => { 'default' => "https://fsx-lustre-client-repo.s3.amazonaws.com/el/8/$basearch" }
)
# Lustre defaults (for CentOS 7.6 and 7.5 only)
default['cluster']['lustre']['version'] = value_for_platform(
  'centos' => {
    '7.6' => "2.10.6",
    '7.5' => "2.10.5",
  }
)
default['cluster']['lustre']['kmod_url'] = value_for_platform(
  'centos' => {
    '7.6' => "https://downloads.whamcloud.com/public/lustre/lustre-2.10.6/el7/client/RPMS/x86_64/kmod-lustre-client-2.10.6-1.el7.x86_64.rpm",
    '7.5' => "https://downloads.whamcloud.com/public/lustre/lustre-2.10.5/el7.5.1804/client/RPMS/x86_64/kmod-lustre-client-2.10.5-1.el7.x86_64.rpm",
  }
)
default['cluster']['lustre']['client_url'] = value_for_platform(
  'centos' => {
    '7.6' => "https://downloads.whamcloud.com/public/lustre/lustre-2.10.6/el7/client/RPMS/x86_64/lustre-client-2.10.6-1.el7.x86_64.rpm",
    '7.5' => "https://downloads.whamcloud.com/public/lustre/lustre-2.10.5/el7.5.1804/client/RPMS/x86_64/lustre-client-2.10.5-1.el7.x86_64.rpm",
  }
)
