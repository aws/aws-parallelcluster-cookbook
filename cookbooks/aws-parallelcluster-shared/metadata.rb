# frozen_string_literal: true

name 'aws-parallelcluster-shared'
maintainer 'Amazon Web Services'
license 'Apache-2.0'
description 'AWS ParallelCluster shared cookbook code'
issues_url 'https://github.com/aws/aws-parallelcluster-cookbook/issues'
source_url 'https://github.com/aws/aws-parallelcluster-cookbook'
chef_version '>= 18'
version '3.16.1'

depends 'yum', '~> 8.0.0'
depends 'yum-epel', '~> 5.0.9'
