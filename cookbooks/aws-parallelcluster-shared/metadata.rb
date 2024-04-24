# frozen_string_literal: true

name 'aws-parallelcluster-shared'
maintainer 'Amazon Web Services'
license 'Apache-2.0'
description 'AWS ParallelCluster shared cookbook code'
issues_url 'https://github.com/aws/aws-parallelcluster-cookbook/issues'
source_url 'https://github.com/aws/aws-parallelcluster-cookbook'
chef_version '>= 18'
version '3.10.0'

supports 'amazon', '>= 2.0'
supports 'centos', '= 7.0'
supports 'ubuntu', '>= 20.04'
supports 'redhat', '= 8.7'

depends 'pyenv', '~> 4.2.3'
depends 'yum', '~> 7.4.13'
depends 'yum-epel', '~> 5.0.2'
