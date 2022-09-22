# frozen_string_literal: true

name 'aws-parallelcluster-slurm'
maintainer 'Amazon Web Services'
license 'Apache-2.0'
description 'Manages Slurm in AWS ParallelCluster'
issues_url 'https://github.com/aws/aws-parallelcluster-cookbook/issues'
source_url 'https://github.com/aws/aws-parallelcluster-cookbook'
chef_version '17.2.29'
version '3.2.1'

supports 'amazon', '>= 2.0'
supports 'centos', '>= 7.0'
supports 'ubuntu', '>= 18.04'

depends 'apt', '~> 7.4.2'
depends 'iptables', '~> 8.0.0'
depends 'line', '~> 4.5.2'
depends 'nfs', '~> 2.6.4'
depends 'openssh', '~> 2.10.3'
depends 'pyenv', '~> 3.5.1'
depends 'selinux', '~> 6.0.4'
depends 'yum', '~> 7.4.0'
depends 'yum-epel', '~> 4.5.0'
