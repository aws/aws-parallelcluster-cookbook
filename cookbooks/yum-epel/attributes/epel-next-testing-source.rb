default['yum']['epel-next-testing-source']['repositoryid'] = 'epel-next-testing-source'
default['yum']['epel-next-testing-source']['description'] =
  "Extra Packages for #{yum_epel_release} - $basearch - Next - Testing Source"
default['yum']['epel-next-testing-source']['mirrorlist'] =
  "https://mirrors.fedoraproject.org/mirrorlist?repo=testing-source-epel#{yum_epel_release}&arch=$basearch"
default['yum']['epel-next-testing-source']['gpgkey'] =
  "https://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-#{yum_epel_release}"
default['yum']['epel-next-testing-source']['gpgcheck'] = true
default['yum']['epel-next-testing-source']['enabled'] = false
default['yum']['epel-next-testing-source']['managed'] = false
default['yum']['epel-next-testing-source']['make_cache'] = true
