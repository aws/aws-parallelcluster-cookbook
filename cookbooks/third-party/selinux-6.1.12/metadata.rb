name             'selinux'
maintainer       'Sous Chefs'
maintainer_email 'help@sous-chefs.org'
license          'Apache-2.0'
description      'Manages SELinux policy state and rules.'
version          '6.1.12'
source_url       'https://github.com/sous-chefs/selinux'
issues_url       'https://github.com/sous-chefs/selinux/issues'
chef_version     '>= 15.3'

%w(redhat centos scientific oracle amazon fedora debian ubuntu).each do |os|
  supports os
end
