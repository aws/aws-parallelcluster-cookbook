# frozen_string_literal: true

#
# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

include_recipe "aws-parallelcluster-platform::enable_chef_error_handler"

os_type 'Validate OS type specified by the user is the same as the OS identified by Ohai'

# Validate init system
raise "Init package #{node['init_package']} not supported." unless systemd? || on_docker?

include_recipe "aws-parallelcluster-environment::init"

# Fetch config must be executed after the mount of the shared folders because the config will be saved there
fetch_config 'Fetch and load cluster configs'

include_recipe "aws-parallelcluster-computefleet::init"
include_recipe "aws-parallelcluster-slurm::init"
include_recipe "aws-parallelcluster-scheduler-plugin::init"
