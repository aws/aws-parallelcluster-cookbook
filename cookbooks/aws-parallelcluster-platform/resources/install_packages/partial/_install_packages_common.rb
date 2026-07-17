# frozen_string_literal: true
#
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
default_action :setup

property :packages, [String, Array],
         default: lazy { default_packages },
         description: 'Packages for the node'

action :install do
  robust_package "install_packages #{new_resource.name}" do
    packages new_resource.packages
  end
end

action :install_base_packages do
  install_packages 'default' do
    action :install
  end unless redhat_on_docker?
end

action :install_extras do
  # nothing
end

action :setup do
  action_install_extras
  action_install_base_packages
end
