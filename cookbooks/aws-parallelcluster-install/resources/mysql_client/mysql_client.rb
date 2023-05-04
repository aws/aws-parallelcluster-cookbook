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

provides :mysql_client
unified_mode true

default_action :setup

use 'partial/_source_link'
use 'partial/_download_and_install'

# MySQL Packages
# We install MySQL packages from the OS repositories for ubuntu platform, while we
# retrieve the packages from S3 for RedHat & derivatives.
action :setup do
  if platform?('ubuntu')
    # An apt update is required to align the apt cache with the current list of available package versions.
    apt_update
    package repository_packages do
      retries 3
      retry_delay 5
    end
  else
    action_download_and_install
  end

  # Add MySQL source file
  action_create_source_link
end

action_class do
  def package_platform
    if arm_instance?
      value_for_platform(
        'default' => "el/7/aarch64"
      )
    else
      value_for_platform(
        'default' => "el/7/x86_64",
        'ubuntu' => {
          '20.04' => "ubuntu/20.04/x86_64",
          '18.04' => "ubuntu/18.04/x86_64",
        }
      )
    end
  end

  def repository_packages
    value_for_platform(
      'default' => %w(mysql-community-devel mysql-community-libs mysql-community-common mysql-community-client-plugins mysql-community-libs-compat),
      'ubuntu' => {
        'default' => %w(libmysqlclient-dev libmysqlclient21),
        '18.04' =>  %w(libmysqlclient-dev libmysqlclient20),
      }
    )
  end

  use 'partial/_package_properties'
end
