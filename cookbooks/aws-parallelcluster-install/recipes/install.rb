# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: install
#
# Copyright:: 2013-2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# Validate OS type specified by the user is the same as the OS identified by Ohai
validate_os_type

return if node['conditions']['ami_bootstrapped']

# == PLATFORM - BASE
include_recipe 'aws-parallelcluster-install::base'

# == PLATFORM - FEATURES
include_recipe "aws-parallelcluster-install::nvidia"
include_recipe "aws-parallelcluster-platform::intel_mpi"
cloudwatch 'Install amazon-cloudwatch-agent'
arm_pl 'Install ARM Performance Library'
include_recipe "aws-parallelcluster-install::intel_hpc" # Intel HPC libraries
efa 'Install EFA'

# == ENVIRONMENT
lustre "Install FSx options" # FSx options
efs 'Install efs-utils'
stunnel 'Install stunnel'
system_authentication "Install packages required for directory service integration"

# == SCHEDULER AND COMPUTE FLEET
include_recipe "aws-parallelcluster-computefleet::clusterstatusmgtd"
mysql_client 'Install mysql client'
include_recipe 'aws-parallelcluster-slurm::install'
include_recipe 'aws-parallelcluster-scheduler-plugin::install' if node['cluster']['scheduler'] == 'plugin'
include_recipe 'aws-parallelcluster-awsbatch::install'

# == WORKSTATIONS
# DCV recipe installs Gnome, X and their dependencies so it must be installed as latest to not break the environment
# used to build the schedulers packages
dcv "Install DCV"

node_attributes "dump node attributes"
