default['yum']['epel']['repositoryid'] = 'epel'
default['yum']['epel']['gpgcheck'] = true
case node['kernel']['machine']
when 'armv7l', 'armv7hl'
  default['yum']['epel']['baseurl'] = 'https://armv7.dev.centos.org/repodir/epel-pass-1/'
  default['yum']['epel']['gpgcheck'] = false
when 's390x'
  default['yum']['epel']['baseurl'] = 'https://kojipkgs.fedoraproject.org/rhel/rc/7/Server/s390x/os/'
  default['yum']['epel']['gpgkey'] =
    'https://kojipkgs.fedoraproject.org/rhel/rc/7/Server/s390x/os/RPM-GPG-KEY-redhat-release'
else
  default['yum']['epel']['description'] = "Extra Packages for #{yum_epel_release} - $basearch"
  default['yum']['epel']['mirrorlist'] =
    "https://mirrors.fedoraproject.org/mirrorlist?repo=epel-#{yum_epel_release}&arch=$basearch"
  default['yum']['epel']['gpgkey'] = "https://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-#{yum_epel_release}"
end
default['yum']['epel']['enabled'] = true
default['yum']['epel']['managed'] = true
default['yum']['epel']['make_cache'] = true
