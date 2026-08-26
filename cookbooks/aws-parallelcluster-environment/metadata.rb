# frozen_string_literal: true

name 'aws-parallelcluster-environment'
maintainer 'Amazon Web Services'
license 'Apache-2.0'
description 'AWS ParallelCluster node environment'
issues_url 'https://github.com/aws/aws-parallelcluster-cookbook/issues'
source_url 'https://github.com/aws/aws-parallelcluster-cookbook'
chef_version '>= 18'
version '3.16.1'

depends 'line', '~> 5.0.0'
depends 'nfs', '~> 5.1.6'

depends 'aws-parallelcluster-shared', '~> 3.16.1'
