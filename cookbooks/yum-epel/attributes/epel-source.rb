default['yum']['epel-source']['repositoryid'] = 'epel-source'
default['yum']['epel-source']['description'] =
  "Extra Packages for #{yum_epel_release} - $basearch - Source"
default['yum']['epel-source']['mirrorlist'] =
  "https://mirrors.fedoraproject.org/mirrorlist?repo=epel-source-#{yum_epel_release}&arch=$basearch"
default['yum']['epel-source']['gpgkey'] =
  "https://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-#{yum_epel_release}"
default['yum']['epel-source']['gpgcheck'] = true
default['yum']['epel-source']['enabled'] = false
default['yum']['epel-source']['managed'] = false
default['yum']['epel-source']['make_cache'] = true
