default['yum']['epel-next-debuginfo']['repositoryid'] = 'epel-next-debuginfo'
default['yum']['epel-next-debuginfo']['description'] =
  "Extra Packages for #{yum_epel_release} - $basearch - Next - Debug"
default['yum']['epel-next-debuginfo']['mirrorlist'] =
  "https://mirrors.fedoraproject.org/mirrorlist?repo=epel-next-debug-#{yum_epel_release}&arch=$basearch"
default['yum']['epel-next-debuginfo']['gpgkey'] =
  "https://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-#{yum_epel_release}"
default['yum']['epel-next-debuginfo']['gpgcheck'] = true
default['yum']['epel-next-debuginfo']['enabled'] = false
default['yum']['epel-next-debuginfo']['managed'] = false
default['yum']['epel-next-debuginfo']['make_cache'] = true
