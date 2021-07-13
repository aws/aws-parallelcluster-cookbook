default['yum']['epel-modular-source']['repositoryid'] = 'epel-modular-source'
default['yum']['epel-modular-source']['description'] = 'Extra Packages for Enterprise Linux Modular $releasever - $basearch - Source'
default['yum']['epel-modular-source']['mirrorlist'] = 'https://mirrors.fedoraproject.org/metalink?repo=epel-modular-source-$releasever&arch=$basearch&infra=$infra&content=$contentdir'
default['yum']['epel-modular-source']['gpgkey'] = 'https://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-8'
default['yum']['epel-modular-source']['failovermethod'] = 'priority'
default['yum']['epel-modular-source']['gpgcheck'] = true
default['yum']['epel-modular-source']['enabled'] = false
default['yum']['epel-modular-source']['managed'] = false
default['yum']['epel-modular-source']['make_cache'] = true
