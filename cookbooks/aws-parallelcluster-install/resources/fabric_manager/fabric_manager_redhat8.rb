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

provides :fabric_manager, platform: 'redhat' do |node|
  node['platform_version'].to_i == 8
end

use 'partial/_fabric_manager_common.rb'
# Temporarely commented to enable the workaround
# use 'partial/_fabric_manager_install_rhel.rb'

# Workaround to download and install nvidia fabric_manager on redhat8 due to bug https://partners.nvidia.com/Bug/ViewBug/4056528
# rpm_package = https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/
action :install_package do
  rpm_package = "#{node['cluster']['nvidia']['fabricmanager']['package']}-#{node['cluster']['nvidia']['fabricmanager']['version']}-1.x86_64.rpm"
  repo_domain = node['cluster']['region'].start_with?("cn-") ? "cn" : "com"
  repo_uri = node['cluster']['nvidia']['cuda']['repository_uri'].gsub('_domain_', repo_domain)
  remote_file rpm_package do
    source "#{repo_uri}/#{rpm_package}"
    mode '0644'
    retries 3
    retry_delay 5
    action :create_if_missing
  end
  package rpm_package do
    retries 3
    retry_delay 5
    source rpm_package
  end
end
