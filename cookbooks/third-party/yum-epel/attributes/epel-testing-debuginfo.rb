default['yum']['epel-testing-debuginfo']['repositoryid'] = 'epel-testing-debuginfo'
default['yum']['epel-testing-debuginfo']['description'] =
  "Extra Packages for #{yum_epel_release} - $basearch - Testing Debug"
default['yum']['epel-testing-debuginfo']['mirrorlist'] =
  "https://mirrors.fedoraproject.org/mirrorlist?repo=testing-debug-epel#{yum_epel_release}&arch=$basearch"
default['yum']['epel-testing-debuginfo']['gpgkey'] =
  "https://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-#{yum_epel_release}"
default['yum']['epel-testing-debuginfo']['gpgcheck'] = true
default['yum']['epel-testing-debuginfo']['enabled'] = false
default['yum']['epel-testing-debuginfo']['managed'] = false
default['yum']['epel-testing-debuginfo']['make_cache'] = true
