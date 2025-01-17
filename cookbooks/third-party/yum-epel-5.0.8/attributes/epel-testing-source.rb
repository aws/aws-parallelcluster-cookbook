default['yum']['epel-testing-source']['repositoryid'] = 'epel-testing-source'
default['yum']['epel-testing-source']['description'] =
  "Extra Packages for #{yum_epel_release} - $basearch - Testing Source"
default['yum']['epel-testing-source']['mirrorlist'] =
  "https://mirrors.fedoraproject.org/mirrorlist?repo=testing-source-epel#{yum_epel_release}&arch=$basearch"
default['yum']['epel-testing-source']['gpgkey'] =
  "https://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-#{yum_epel_release}"
default['yum']['epel-testing-source']['gpgcheck'] = true
default['yum']['epel-testing-source']['enabled'] = false
default['yum']['epel-testing-source']['managed'] = false
default['yum']['epel-testing-source']['make_cache'] = true
