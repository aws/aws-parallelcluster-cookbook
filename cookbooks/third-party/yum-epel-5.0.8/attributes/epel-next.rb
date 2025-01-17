default['yum']['epel-next']['repositoryid'] = 'epel-next'
default['yum']['epel-next']['gpgcheck'] = true
default['yum']['epel-next']['description'] = 'Extra Packages for $releasever - Next - $basearch'
default['yum']['epel-next']['mirrorlist'] =
  "https://mirrors.fedoraproject.org/mirrorlist?repo=epel-next-#{yum_epel_release}&arch=$basearch"
default['yum']['epel-next']['gpgkey'] =
  "https://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-#{yum_epel_release}"
default['yum']['epel-next']['enabled'] = true
default['yum']['epel-next']['managed'] = true
default['yum']['epel-next']['make_cache'] = true
