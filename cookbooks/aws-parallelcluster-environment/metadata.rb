# frozen_string_literal: true

name 'aws-parallelcluster-environment'
maintainer 'Amazon Web Services'
license 'Apache-2.0'
description 'AWS ParallelCluster node environment'
issues_url 'https://github.com/aws/aws-parallelcluster-cookbook/issues'
source_url 'https://github.com/aws/aws-parallelcluster-cookbook'
chef_version '>= 18'
version '3.9.3'

supports 'amazon', '= 2.0'
supports 'centos', '= 7.0'
supports 'ubuntu', '>= 20.04'
supports 'redhat', '= 8.7'

depends 'line', '~> 4.5.13'
depends 'nfs', '~> 5.1.2'

depends 'aws-parallelcluster-shared', '~> 3.9.3'
