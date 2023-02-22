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
include_recipe "aws-parallelcluster-install::sudo"
include_recipe "aws-parallelcluster-install::users"
include_recipe "aws-parallelcluster-install::disable_services"

package_repos 'setup the repositories'

include_recipe "aws-parallelcluster-install::directories"

install_packages 'Install OS and extra packages'

include_recipe "aws-parallelcluster-install::base_isolated"
include_recipe "aws-parallelcluster-install::python"
include_recipe "aws-parallelcluster-install::cfn_bootstrap"
include_recipe 'aws-parallelcluster-install::node'
include_recipe "aws-parallelcluster-install::awscli"

include_recipe "aws-parallelcluster-install::openssh"

include_recipe "aws-parallelcluster-install::disable_selinux"

# Install LICENSE README
include_recipe "aws-parallelcluster-install::license_readme"

nfs 'install NFS daemon'
ephemeral_drives 'install'
ec2_udev_rules 'configure udev'

include_recipe "aws-parallelcluster-install::gc_thresh_values"

include_recipe "aws-parallelcluster-install::supervisord"

include_recipe "aws-parallelcluster-install::ami_cleanup"

# Configure cron and anacron
include_recipe "aws-parallelcluster-install::cron"

# Install Amazon Time Sync
include_recipe "aws-parallelcluster-install::chrony" unless redhat_ubi?

c_states 'disable x86_64 C states'
