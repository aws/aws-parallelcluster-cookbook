default['yum']['epel-testing-modular-debuginfo']['repositoryid'] = 'epel-testing-modular-debuginfo'
default['yum']['epel-testing-modular-debuginfo']['description'] = 'Extra Packages for Enterprise Linux Modular $releasever - Testing - $basearch - Debug'
default['yum']['epel-testing-modular-debuginfo']['mirrorlist'] = 'https://mirrors.fedoraproject.org/metalink?repo=testing-modular-debug-epel$releasever&arch=$basearch&infra=$infra&content=$contentdir'
default['yum']['epel-testing-modular-debuginfo']['gpgkey'] = 'https://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-8'
default['yum']['epel-testing-modular-debuginfo']['failovermethod'] = 'priority'
default['yum']['epel-testing-modular-debuginfo']['gpgcheck'] = true
default['yum']['epel-testing-modular-debuginfo']['enabled'] = false
default['yum']['epel-testing-modular-debuginfo']['managed'] = false
default['yum']['epel-testing-modular-debuginfo']['make_cache'] = true
