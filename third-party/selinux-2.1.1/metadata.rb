name             'selinux'
maintainer       'Chef Software, Inc.'
maintainer_email 'cookbooks@chef.io'
license          'Apache-2.0'
description      'Manages SELinux policy state'
version          '2.1.1'

%w(redhat centos scientific oracle amazon fedora).each do |os|
  supports os
end

source_url 'https://github.com/chef-cookbooks/selinux'
issues_url 'https://github.com/chef-cookbooks/selinux/issues'
chef_version '>= 12.7' if respond_to?(:chef_version)
