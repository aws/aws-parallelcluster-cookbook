maintainer 'Eric G. Wolfe'
maintainer_email 'eric.wolfe@gmail.com'
license 'Apache-2.0'
description 'Installs and configures NFS, and NFS exports'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
name 'nfs'
version '3.0.0'
source_url 'https://github.com/atomic-penguin/cookbook-nfs' if respond_to?(:source_url)
issues_url 'https://github.com/atomic-penguin/cookbook-nfs/issues' if respond_to?(:issues_url)
chef_version '>= 13.0' if respond_to?(:chef_version)

supports 'ubuntu', '>= 15.04'
supports 'debian', '>= 10.0'
supports 'centos', '>= 7.0'
supports 'redhat', '>= 7.0'
supports 'scientific', '>= 7.0'
supports 'oracle', '>= 7.0'
supports 'sles', '>= 11.1'
supports 'freebsd', '>= 9.3'

depends 'line', '~> 2.1'
