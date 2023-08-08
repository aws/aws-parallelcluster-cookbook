default['yum']['epel-next-testing-debuginfo']['repositoryid'] = 'epel-next-testing-debuginfo'
default['yum']['epel-next-testing-debuginfo']['description'] =
  "Extra Packages for #{yum_epel_release} - $basearch - Next - Testing Debug"
default['yum']['epel-next-testing-debuginfo']['mirrorlist'] =
  "https://mirrors.fedoraproject.org/mirrorlist?repo=epel-testing-next-debug-#{yum_epel_release}&arch=$basearch"
default['yum']['epel-next-testing-debuginfo']['gpgkey'] =
  "https://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-#{yum_epel_release}"
default['yum']['epel-next-testing-debuginfo']['gpgcheck'] = true
default['yum']['epel-next-testing-debuginfo']['enabled'] = false
default['yum']['epel-next-testing-debuginfo']['managed'] = false
default['yum']['epel-next-testing-debuginfo']['make_cache'] = true
