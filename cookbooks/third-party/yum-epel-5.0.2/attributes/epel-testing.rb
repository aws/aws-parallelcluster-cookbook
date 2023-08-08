default['yum']['epel-testing']['repositoryid'] = 'epel-testing'
default['yum']['epel-testing']['description'] =
  "Extra Packages for #{yum_epel_release} - $basearch - Testing "
default['yum']['epel-testing']['mirrorlist'] =
  "https://mirrors.fedoraproject.org/mirrorlist?repo=testing-epel#{yum_epel_release}&arch=$basearch"
default['yum']['epel-testing']['gpgkey'] =
  "https://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-#{yum_epel_release}"
default['yum']['epel-testing']['gpgcheck'] = true
default['yum']['epel-testing']['enabled'] = false
default['yum']['epel-testing']['managed'] = false
default['yum']['epel-testing']['make_cache'] = true
