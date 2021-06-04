name             'ulimit'
maintainer       'Brian Hatfield'
maintainer_email 'bmhatfield@gmail.com'
license          'Apache-2.0'
description      'Resources for manaing ulimits'
version          '1.1.1'

%w(amazon centos redhat scientific oracle fedora debian ubuntu).each do |os|
  supports os
end

source_url 'https://github.com/bmhatfield/chef-ulimit'
issues_url 'https://github.com/bmhatfield/chef-ulimit/issues'
chef_version '>= 12.7'
