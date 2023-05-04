default['yum']['epel-next-debuginfo']['repositoryid'] = 'epel-next-debuginfo'
default['yum']['epel-next-debuginfo']['description'] =
  "Extra Packages for #{node['platform_version'].to_i} - $basearch - Next - Debug"
default['yum']['epel-next-debuginfo']['mirrorlist'] =
  "https://mirrors.fedoraproject.org/mirrorlist?repo=epel-next-debug-#{node['platform_version'].to_i}&arch=$basearch"
default['yum']['epel-next-debuginfo']['gpgkey'] =
  "https://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-#{node['platform_version'].to_i}"
default['yum']['epel-next-debuginfo']['gpgcheck'] = true
default['yum']['epel-next-debuginfo']['enabled'] = false
default['yum']['epel-next-debuginfo']['managed'] = false
default['yum']['epel-next-debuginfo']['make_cache'] = true
