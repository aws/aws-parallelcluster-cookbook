name             'pyenv'
maintainer       'Sous Chefs'
maintainer_email 'help@sous-chefs.org'
license          'Apache-2.0'
description      'Manages pyenv and its installed Python versions.'
issues_url       'https://github.com/sous-chefs/pyenv/issues'
source_url       'https://github.com/sous-chefs/pyenv'
version          '3.5.1'
chef_version     '>= 14.0'

%w(
  ubuntu
  linuxmint
  debian
  redhat
  centos
  fedora
  amazon
  scientific
  opensuse
  opensuseleap
  oracle
).each do |os|
  supports os
end
