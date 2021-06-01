default['yum']['epel-playground']['repositoryid'] = 'epel-playground'
default['yum']['epel-playground']['description'] = 'Extra Packages for Enterprise Linux $releasever - Playground - $basearch'
default['yum']['epel-playground']['mirrorlist'] = 'https://mirrors.fedoraproject.org/metalink?repo=playground-epel$releasever&arch=$basearch&infra=$infra&content=$contentdir'
default['yum']['epel-playground']['gpgkey'] = 'https://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-8'
default['yum']['epel-playground']['failovermethod'] = 'priority'
default['yum']['epel-playground']['gpgcheck'] = true
default['yum']['epel-playground']['enabled'] = false
default['yum']['epel-playground']['managed'] = false
default['yum']['epel-playground']['make_cache'] = true
