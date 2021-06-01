default['yum']['epel-testing-modular']['repositoryid'] = 'epel-testing-modular'
default['yum']['epel-testing-modular']['description'] = 'Extra Packages for Enterprise Linux Modular $releasever - Testing - $basearch'
default['yum']['epel-testing-modular']['mirrorlist'] = 'https://mirrors.fedoraproject.org/metalink?repo=testing-modular-epel$releasever&arch=$basearch&infra=$infra&content=$contentdir'
default['yum']['epel-testing-modular']['gpgkey'] = 'https://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-8'
default['yum']['epel-testing-modular']['failovermethod'] = 'priority'
default['yum']['epel-testing-modular']['gpgcheck'] = true
default['yum']['epel-testing-modular']['enabled'] = false
default['yum']['epel-testing-modular']['managed'] = false
default['yum']['epel-testing-modular']['make_cache'] = true
