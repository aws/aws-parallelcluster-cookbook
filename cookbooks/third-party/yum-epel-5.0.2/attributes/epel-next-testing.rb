default['yum']['epel-next-testing']['repositoryid'] = 'epel-next-testing'
default['yum']['epel-next-testing']['description'] =
  "Extra Packages for #{yum_epel_release} - $basearch - Next - Testing"
default['yum']['epel-next-testing']['mirrorlist'] =
  "https://mirrors.fedoraproject.org/mirrorlist?repo=epel-testing-next-#{yum_epel_release}&arch=$basearch"
default['yum']['epel-next-testing']['gpgkey'] =
  "https://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-#{yum_epel_release}"
default['yum']['epel-next-testing']['gpgcheck'] = true
default['yum']['epel-next-testing']['enabled'] = false
default['yum']['epel-next-testing']['managed'] = false
default['yum']['epel-next-testing']['make_cache'] = true
