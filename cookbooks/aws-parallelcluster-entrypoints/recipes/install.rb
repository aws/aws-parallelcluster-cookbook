# frozen_string_literal: true

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

os_type 'Validate OS type specified by the user is the same as the OS identified by Ohai'

return if node['conditions']['ami_bootstrapped']

include_recipe "aws-parallelcluster-shared::setup_envars"

include_recipe 'aws-parallelcluster-platform::install'
include_recipe 'aws-parallelcluster-environment::install'
include_recipe 'aws-parallelcluster-computefleet::install'
include_recipe 'aws-parallelcluster-slurm::install'
include_recipe 'aws-parallelcluster-scheduler-plugin::install'
include_recipe 'aws-parallelcluster-awsbatch::install'

# == WORKSTATIONS
# DCV recipe installs Gnome, X and their dependencies so it must be installed as latest to not break the environment
# used to build the schedulers packages
dcv "Install DCV"

node_attributes "dump node attributes"
