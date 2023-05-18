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

provides :modules, platform: 'ubuntu', platform_version: '18.04'

use 'partial/_modules_common.rb'
use 'partial/_modules_apt.rb'

action_class do
  def packages
    %w(tcl-dev environment-modules)
  end

  def modules_home
    '/usr/share/modules'
  end
end
