# frozen_string_literal: true

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
#

include_recipe "aws-parallelcluster-environment::cfnconfig_mixed"
include_recipe "aws-parallelcluster-environment::mount_shared"
cloudwatch "Configure CloudWatch" do
  action :configure
end
include_recipe "aws-parallelcluster-environment::network_interfaces"
include_recipe 'aws-parallelcluster-environment::imds'
include_recipe "aws-parallelcluster-environment::directory_service"

# Custom action setup must be executed after cfnconfig file creation
include_recipe "aws-parallelcluster-environment::custom_actions_setup"
