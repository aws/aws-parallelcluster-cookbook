default['yum']['epel-testing-debuginfo']['repositoryid'] = 'epel-testing-debuginfo'

if platform?('amazon')
  default['yum']['epel-testing-debuginfo']['description'] = 'Extra Packages for 7 - $basearch - Testing Debug'
  default['yum']['epel-testing-debuginfo']['mirrorlist'] = 'https://mirrors.fedoraproject.org/mirrorlist?repo=testing-debug-epel7&arch=$basearch'
  default['yum']['epel-testing-debuginfo']['gpgkey'] = 'https://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7'
else
  default['yum']['epel-testing-debuginfo']['description'] = "Extra Packages for #{node['platform_version'].to_i} - $basearch - Testing Debug"
  default['yum']['epel-testing-debuginfo']['mirrorlist'] = "https://mirrors.fedoraproject.org/mirrorlist?repo=testing-debug-epel#{node['platform_version'].to_i}&arch=$basearch"
  default['yum']['epel-testing-debuginfo']['gpgkey'] = "https://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-#{node['platform_version'].to_i}"
end
default['yum']['epel-testing-debuginfo']['failovermethod'] = 'priority'
default['yum']['epel-testing-debuginfo']['gpgcheck'] = true
default['yum']['epel-testing-debuginfo']['enabled'] = false
default['yum']['epel-testing-debuginfo']['managed'] = false
default['yum']['epel-testing-debuginfo']['make_cache'] = true
