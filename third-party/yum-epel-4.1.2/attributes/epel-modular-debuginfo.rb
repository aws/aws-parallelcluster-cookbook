default['yum']['epel-modular-debuginfo']['repositoryid'] = 'epel-modular-debuginfo'
default['yum']['epel-modular-debuginfo']['description'] = 'Extra Packages for Enterprise Linux Modular $releasever - $basearch - Debug'
default['yum']['epel-modular-debuginfo']['mirrorlist'] = 'https://mirrors.fedoraproject.org/metalink?repo=epel-modular-debug-$releasever&arch=$basearch&infra=$infra&content=$contentdir'
default['yum']['epel-modular-debuginfo']['gpgkey'] = 'https://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-8'
default['yum']['epel-modular-debuginfo']['failovermethod'] = 'priority'
default['yum']['epel-modular-debuginfo']['gpgcheck'] = true
default['yum']['epel-modular-debuginfo']['enabled'] = false
default['yum']['epel-modular-debuginfo']['managed'] = false
default['yum']['epel-modular-debuginfo']['make_cache'] = true
