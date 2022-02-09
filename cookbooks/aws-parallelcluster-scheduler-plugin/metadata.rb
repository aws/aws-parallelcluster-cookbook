# frozen_string_literal: true

name 'aws-parallelcluster-scheduler-plugin'
maintainer 'Amazon Web Services'
license 'Apache-2.0'
description 'Manages Custom Scheduler in AWS ParallelCluster'
issues_url 'https://github.com/aws/aws-parallelcluster/issues'
source_url 'https://github.com/aws/aws-parallelcluster-cookbook'
chef_version '17.2.29'
version '3.1.1'

supports 'amazon', '>= 2.0'
supports 'centos', '>= 7.0'
supports 'ubuntu', '>= 18.04'

depends 'apt', '~> 7.4.0'
depends 'iptables', '~> 8.0.0'
depends 'line', '~> 4.0.1'
depends 'nfs', '~> 2.6.4'
depends 'openssh', '~> 2.9.1'
depends 'pyenv', '~> 3.4.2'
depends 'selinux', '~> 3.1.1'
depends 'yum', '~> 6.1.1'
depends 'yum-epel', '~> 4.1.2'
