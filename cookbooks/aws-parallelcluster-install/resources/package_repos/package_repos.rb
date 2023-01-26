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

provides :package_repos
unified_mode true

action :setup do
  case node['platform_family']
  when 'rhel', 'amazon'
    include_recipe 'yum'
    if platform_family?('amazon')
      alinux_extras_topic 'epel'
    elsif platform?('centos')
      include_recipe "yum-epel"
    end

    # the epel recipe doesn't work on aarch64, needs epel-release package
    package 'epel-release' if node['platform_version'].to_i == 7 && node['kernel']['machine'] == 'aarch64'

    unless node['platform_version'].to_i < 7
      execute 'yum-config-manager_skip_if_unavail' do
        command "yum-config-manager --setopt=\*.skip_if_unavailable=1 --save"
      end
    end

  when 'debian'
    apt_update
  end
end
