# frozen_string_literal: true

name 'aws-parallelcluster-tests'
maintainer 'Amazon Web Services'
license 'Apache-2.0'
description 'Common AWS ParallelCluster resources and attributes'
issues_url 'https://github.com/aws/aws-parallelcluster-cookbook/issues'
source_url 'https://github.com/aws/aws-parallelcluster-cookbook'
chef_version '>= 18'
version '3.12.0'

depends 'aws-parallelcluster-shared', '~> 3.12.0'
depends 'aws-parallelcluster-platform', '~> 3.12.0'
depends 'aws-parallelcluster-environment', '~> 3.12.0'
depends 'aws-parallelcluster-computefleet', '~> 3.12.0'
depends 'aws-parallelcluster-slurm', '~> 3.12.0'
