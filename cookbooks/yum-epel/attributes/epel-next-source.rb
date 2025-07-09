default['yum']['epel-next-source']['repositoryid'] = 'epel-next-source'
default['yum']['epel-next-source']['description'] =
  "Extra Packages for #{yum_epel_release} $basearch - Next -Source"
default['yum']['epel-next-source']['mirrorlist'] =
  "https://mirrors.fedoraproject.org/mirrorlist?repo=epel-next-source-#{yum_epel_release}&arch=$basearch"
default['yum']['epel-next-source']['gpgkey'] =
  "https://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-#{yum_epel_release}"
default['yum']['epel-next-source']['gpgcheck'] = true
default['yum']['epel-next-source']['enabled'] = false
default['yum']['epel-next-source']['managed'] = false
default['yum']['epel-next-source']['make_cache'] = true
