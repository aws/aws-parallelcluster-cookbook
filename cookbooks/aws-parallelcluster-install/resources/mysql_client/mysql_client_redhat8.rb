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

provides :mysql_client, platform: 'redhat' do |node|
  node['platform_version'].to_i == 8
end
unified_mode true

default_action :setup

use 'partial/_source_link'
use 'partial/_download_and_install'
use 'partial/_validate'

action :setup do
  action_download_and_install

  # Add MySQL source file
  action_create_source_link
end

action_class do
  def package_platform
    arm_instance? ? "el/7/aarch64" : "el/7/x86_64"
  end

  def expected_version
    "8.0.31"
  end

  def repository_packages
    %w(mysql-community-devel mysql-community-libs mysql-community-common mysql-community-client-plugins mysql-community-libs-compat)
  end

  use 'partial/_package_properties'
end
