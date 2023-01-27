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

action :setup do
  if platform?('ubuntu') && arm_instance?
    package node['cluster']['mysql']['repository']['packages'] do
      retries 3
      retry_delay 5
    end
  else

    new_resource.package_installer = value_for_platform(
      'default' => "yum install -y",
      'ubuntu' => { 'default' => "apt install -y" }
    )

    action_download_and_install

  end

  # Add MySQL source file
  action_create_source_link
end
