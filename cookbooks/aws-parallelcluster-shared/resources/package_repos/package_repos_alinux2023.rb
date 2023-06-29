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

provides :package_repos, platform: 'amazon' do |node|
  node['platform_version'].to_i == 2023
end
unified_mode true

use 'partial/_package_repos_rpm.rb'

default_action :setup

action :setup do
  include_recipe 'yum'
  # include_recipe "yum-epel"

  package 'yum-utils' do
    retries 3
    retry_delay 5
  end

  # execute 'yum-config-manager-rhel' do
  #   # Needed by hwloc-devel blas-devel libedit-devel and glibc-static packages
  #   command "yum-config-manager --enable codeready-builder-for-rhel-8-rhui-rpms"
  # end unless on_docker?
  #
  # execute 'yum-config-manager_skip_if_unavail' do
  #   command "yum-config-manager --setopt=\*.skip_if_unavailable=1 --save"
  # end
end

action :update do
  # Do nothing
end
