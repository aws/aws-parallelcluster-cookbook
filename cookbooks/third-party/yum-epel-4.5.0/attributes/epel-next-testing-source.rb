default['yum']['epel-next-testing-source']['repositoryid'] = 'epel-next-testing-source'
default['yum']['epel-next-testing-source']['description'] =
  "Extra Packages for #{node['platform_version'].to_i} - $basearch - Next - Testing Source"
default['yum']['epel-next-testing-source']['mirrorlist'] =
  "https://mirrors.fedoraproject.org/mirrorlist?repo=testing-source-epel#{node['platform_version'].to_i}&arch=$basearch"
default['yum']['epel-next-testing-source']['gpgkey'] =
  "https://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-#{node['platform_version'].to_i}"
default['yum']['epel-next-testing-source']['gpgcheck'] = true
default['yum']['epel-next-testing-source']['enabled'] = false
default['yum']['epel-next-testing-source']['managed'] = false
default['yum']['epel-next-testing-source']['make_cache'] = true
