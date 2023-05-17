# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: base
#
# Copyright:: 2013-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

include_recipe "aws-parallelcluster-common::setup_envars"
include_recipe "aws-parallelcluster-platform::sudo_install"
include_recipe "aws-parallelcluster-platform::users"
include_recipe "aws-parallelcluster-platform::disable_services"

package_repos 'setup the repositories'

include_recipe "aws-parallelcluster-platform::directories"

install_packages 'Install OS and extra packages'

include_recipe "aws-parallelcluster-environment::isolated_install"
include_recipe "aws-parallelcluster-platform::cookbook_virtualenv"
include_recipe "aws-parallelcluster-environment::cfn_bootstrap"
include_recipe 'aws-parallelcluster-computefleet::node'
include_recipe "aws-parallelcluster-platform::awscli"

include_recipe "openssh"

include_recipe "aws-parallelcluster-platform::disable_selinux"

# Install LICENSE README
include_recipe "aws-parallelcluster-platform::license_readme"

nfs 'install NFS daemon'
ephemeral_drives 'install'
ec2_udev_rules 'configure udev'

include_recipe "aws-parallelcluster-platform::gc_thresh_values"

include_recipe "aws-parallelcluster-platform::supervisord"

include_recipe "aws-parallelcluster-platform::ami_cleanup"

# Configure cron and anacron
include_recipe "aws-parallelcluster-platform::cron"

# Install Amazon Time Sync
include_recipe "aws-parallelcluster-install::chrony" unless redhat_ubi?

c_states 'disable x86_64 C states'
