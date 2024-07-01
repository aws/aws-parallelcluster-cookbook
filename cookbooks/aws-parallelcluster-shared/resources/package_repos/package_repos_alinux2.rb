# frozen_string_literal: true

# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

provides :package_repos, platform: 'amazon', platform_version: '2'
unified_mode true

use 'partial/_package_repos_rpm.rb'

default_action :setup

action :setup do
  include_recipe 'yum'
  alinux_extras_topic 'epel'
  if aws_region.start_with?("us-iso")
      bash "Disable epel repo" do
        user 'root'
        group 'root'
        code <<-EPEL
        set -e
        yum-config-manager --disable epel
        EPEL
      end
    end
end

action :update do
  # Do nothing
end
