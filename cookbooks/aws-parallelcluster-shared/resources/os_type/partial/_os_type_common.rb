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

unified_mode true
default_action :validate

property :base_os, String

action :validate do
  new_resource.base_os ||= node['cluster']['base_os']

  raise_os_not_match(current_os, new_resource.base_os) if new_resource.base_os != current_os
end

def raise_os_not_match(current_os, specified_os)
  raise "The custom AMI you have provided uses the #{current_os} OS. " \
        "However, the base_os specified in your config file is #{specified_os}. " \
        "Please either use an AMI with the #{specified_os} OS or update the base_os " \
        "setting in your configuration file to #{current_os}."
end
