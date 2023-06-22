default['yum']['epel-next-testing']['repositoryid'] = 'epel-next-testing'
default['yum']['epel-next-testing']['description'] =
  "Extra Packages for #{node['platform_version'].to_i} - $basearch - Next - Testing"
default['yum']['epel-next-testing']['mirrorlist'] =
  "https://mirrors.fedoraproject.org/mirrorlist?repo=epel-testing-next-#{node['platform_version'].to_i}&arch=$basearch"
default['yum']['epel-next-testing']['gpgkey'] =
  "https://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-#{node['platform_version'].to_i}"
default['yum']['epel-next-testing']['gpgcheck'] = true
default['yum']['epel-next-testing']['enabled'] = false
default['yum']['epel-next-testing']['managed'] = false
default['yum']['epel-next-testing']['make_cache'] = true
