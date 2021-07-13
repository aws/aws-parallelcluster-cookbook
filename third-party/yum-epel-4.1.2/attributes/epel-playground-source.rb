default['yum']['epel-playground-source']['repositoryid'] = 'epel-playground-source'
default['yum']['epel-playground-source']['description'] = 'Extra Packages for Enterprise Linux $releasever - Playground - $basearch - Source'
default['yum']['epel-playground-source']['mirrorlist'] = 'https://mirrors.fedoraproject.org/metalink?repo=playground-source-epel$releasever&arch=$basearch&infra=$infra&content=$contentdir'
default['yum']['epel-playground-source']['gpgkey'] = 'https://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-8'
default['yum']['epel-playground-source']['failovermethod'] = 'priority'
default['yum']['epel-playground-source']['gpgcheck'] = true
default['yum']['epel-playground-source']['enabled'] = false
default['yum']['epel-playground-source']['managed'] = false
default['yum']['epel-playground-source']['make_cache'] = true
