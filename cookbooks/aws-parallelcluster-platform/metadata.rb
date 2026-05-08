# frozen_string_literal: true

name 'aws-parallelcluster-platform'
maintainer 'Amazon Web Services'
license 'Apache-2.0'
description 'AWS ParallelCluster node platform'
issues_url 'https://github.com/aws/aws-parallelcluster-cookbook/issues'
source_url 'https://github.com/aws/aws-parallelcluster-cookbook'
chef_version '>= 18'
version '3.15.1'

depends 'line', '~> 4.5.21'

depends 'aws-parallelcluster-shared', '~> 3.15.1'
