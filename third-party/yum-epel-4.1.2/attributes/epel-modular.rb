default['yum']['epel-modular']['repositoryid'] = 'epel-modular'
default['yum']['epel-modular']['description'] = 'Extra Packages for Enterprise Linux Modular $releasever - $basearch'
default['yum']['epel-modular']['mirrorlist'] = 'https://mirrors.fedoraproject.org/metalink?repo=epel-modular-$releasever&arch=$basearch&infra=$infra&content=$contentdir'
default['yum']['epel-modular']['gpgkey'] = 'https://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-8'
default['yum']['epel-modular']['failovermethod'] = 'priority'
default['yum']['epel-modular']['gpgcheck'] = true
default['yum']['epel-modular']['enabled'] = false
default['yum']['epel-modular']['managed'] = false
default['yum']['epel-modular']['make_cache'] = true
