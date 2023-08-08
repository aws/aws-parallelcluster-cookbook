default['yum']['epel-debuginfo']['repositoryid'] = 'epel-debuginfo'
default['yum']['epel-debuginfo']['description'] =
  "Extra Packages for #{yum_epel_release} - $basearch - Debug"
default['yum']['epel-debuginfo']['mirrorlist'] =
  "https://mirrors.fedoraproject.org/mirrorlist?repo=epel-debug-#{yum_epel_release}&arch=$basearch"
default['yum']['epel-debuginfo']['gpgkey'] =
  "https://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-#{yum_epel_release}"
default['yum']['epel-debuginfo']['gpgcheck'] = true
default['yum']['epel-debuginfo']['enabled'] = false
default['yum']['epel-debuginfo']['managed'] = false
default['yum']['epel-debuginfo']['make_cache'] = true
