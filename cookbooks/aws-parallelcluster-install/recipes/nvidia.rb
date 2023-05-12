# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: nvidia
#
# Copyright:: 2013-2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

nvidia_driver 'Install nvidia driver'
include_recipe "aws-parallelcluster-install::cuda"
gdrcopy 'Install Nvidia gdrcopy'

# Add NVIDIA repo for fabric manager and datacenter-gpu-manager
repo_domain = node['cluster']['region'].start_with?("cn-") ? "cn" : "com"
repo_uri = node['cluster']['nvidia']['cuda']['repository_uri'].gsub('_domain_', repo_domain)
package_repos 'add nvidia-repo' do
  action :add
  repo_name "nvidia-repo"
  baseurl repo_uri
  gpgkey "#{repo_uri}/#{node['cluster']['nvidia']['fabricmanager']['repository_key']}"
end

fabric_manager 'Install Nvidia Fabric Manager'

nvidia_dcgm 'install datacenter-gpu-manager'

remove_package_repository("nvidia-repo")
