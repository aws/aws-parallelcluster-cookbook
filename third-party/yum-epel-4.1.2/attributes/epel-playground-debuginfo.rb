default['yum']['epel-playground-debuginfo']['repositoryid'] = 'epel-playground-debuginfo'
default['yum']['epel-playground-debuginfo']['description'] = 'Extra Packages for Enterprise Linux $releasever - Playground - $basearch - Debug'
default['yum']['epel-playground-debuginfo']['mirrorlist'] = 'https://mirrors.fedoraproject.org/metalink?repo=playground-debug-epel$releasever&arch=$basearch&infra=$infra&content=$contentdir'
default['yum']['epel-playground-debuginfo']['gpgkey'] = 'https://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-8'
default['yum']['epel-playground-debuginfo']['failovermethod'] = 'priority'
default['yum']['epel-playground-debuginfo']['gpgcheck'] = true
default['yum']['epel-playground-debuginfo']['enabled'] = false
default['yum']['epel-playground-debuginfo']['managed'] = false
default['yum']['epel-playground-debuginfo']['make_cache'] = true
