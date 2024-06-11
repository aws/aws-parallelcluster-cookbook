# frozen_string_literal: true

name 'aws-parallelcluster-awsbatch'
maintainer 'Amazon Web Services'
license 'Apache-2.0'
description 'Manages AWS Batch in AWS ParallelCluster'
issues_url 'https://github.com/aws/aws-parallelcluster/issues'
source_url 'https://github.com/aws/aws-parallelcluster-cookbook'
chef_version '>= 18'
version '3.10.0'

supports 'amazon', '>= 2.0'
supports 'centos', '>= 7.0'
supports 'ubuntu', '>= 20.04'

depends 'apt', '~> 7.5.22'
depends 'iptables', '~> 8.0.0'
depends 'nfs', '~> 5.1.2'
depends 'line', '~> 4.5.13'
depends 'openssh', '~> 2.11.12'
depends 'pyenv', '~> 4.2.3'
depends 'yum', '~> 7.4.13'
depends 'yum-epel', '~> 5.0.2'
depends 'aws-parallelcluster-shared', '~> 3.10.0'
