default['yum']['epel-testing-modular-source']['repositoryid'] = 'epel-testing-modular-source'
default['yum']['epel-testing-modular-source']['description'] = 'Extra Packages for Enterprise Linux Modular $releasever- Testing - $basearch - Source'
default['yum']['epel-testing-modular-source']['mirrorlist'] = 'https://mirrors.fedoraproject.org/metalink?repo=testing-modular-source-epel$releasever&arch=$basearch&infra=$infra&content=$contentdir'
default['yum']['epel-testing-modular-source']['gpgkey'] = 'https://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-8'
default['yum']['epel-testing-modular-source']['failovermethod'] = 'priority'
default['yum']['epel-testing-modular-source']['gpgcheck'] = true
default['yum']['epel-testing-modular-source']['enabled'] = false
default['yum']['epel-testing-modular-source']['managed'] = false
default['yum']['epel-testing-modular-source']['make_cache'] = true
