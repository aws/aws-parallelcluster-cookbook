name 'yum'
maintainer 'Chef Software, Inc.'
maintainer_email 'cookbooks@chef.io'
license 'Apache-2.0'
description 'Configures various yum components on Red Hat-like systems'
version '5.1.0'

%w(amazon centos fedora oracle redhat scientific zlinux).each do |os|
  supports os
end

source_url 'https://github.com/chef-cookbooks/yum'
issues_url 'https://github.com/chef-cookbooks/yum/issues'
chef_version '>= 12.14'
