name             'selinux'
maintainer       'Chef Software, Inc.'
maintainer_email 'cookbooks@chef.io'
license          'Apache-2.0'
description      'Manages SELinux policy state and rules.'
version          '3.1.1'

%w(redhat centos scientific oracle amazon fedora).each do |os|
  supports os
end

source_url 'https://github.com/chef-cookbooks/selinux'
issues_url 'https://github.com/chef-cookbooks/selinux/issues'
chef_version '>= 13.0'
