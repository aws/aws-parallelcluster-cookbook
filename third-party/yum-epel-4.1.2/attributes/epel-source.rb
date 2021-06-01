default['yum']['epel-source']['repositoryid'] = 'epel-source'

if platform?('amazon')
  default['yum']['epel-source']['description'] = 'Extra Packages for 7 - $basearch - Source'
  default['yum']['epel-source']['mirrorlist'] = 'https://mirrors.fedoraproject.org/mirrorlist?repo=epel-source-7&arch=$basearch'
  default['yum']['epel-source']['gpgkey'] = 'https://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7'
else
  default['yum']['epel-source']['description'] = "Extra Packages for #{node['platform_version'].to_i} - $basearch - Source"
  default['yum']['epel-source']['mirrorlist'] = "https://mirrors.fedoraproject.org/mirrorlist?repo=epel-source-#{node['platform_version'].to_i}&arch=$basearch"
  default['yum']['epel-source']['gpgkey'] = "https://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-#{node['platform_version'].to_i}"
end
default['yum']['epel-source']['failovermethod'] = 'priority'
default['yum']['epel-source']['gpgcheck'] = true
default['yum']['epel-source']['enabled'] = false
default['yum']['epel-source']['managed'] = false
default['yum']['epel-source']['make_cache'] = true
