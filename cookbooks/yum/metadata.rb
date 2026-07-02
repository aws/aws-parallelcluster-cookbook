# frozen_string_literal: true

name              'yum'
maintainer        'Sous Chefs'
maintainer_email  'help@sous-chefs.org'
license           'Apache-2.0'
description       'Provides yum_globalconfig and dnf_module resources for YUM/DNF systems'
version           '8.0.0'
source_url        'https://github.com/sous-chefs/yum'
issues_url        'https://github.com/sous-chefs/yum/issues'
chef_version      '>= 15.3'

supports 'almalinux', '>= 8.0'
supports 'amazon', '>= 2023.0'
supports 'centos_stream', '>= 9.0'
supports 'fedora'
supports 'oracle', '>= 8.0'
supports 'redhat', '>= 8.0'
supports 'rocky', '>= 8.0'
