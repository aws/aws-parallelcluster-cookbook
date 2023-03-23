# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: fabric_manager
#
# Copyright:: 2013-2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.


return unless node['cluster']['nvidia']['enabled'] == 'yes' || node['cluster']['nvidia']['enabled'] == true

# NVIDIA Fabric Manager not present on ARM
return if arm_instance?

# Install NVIDIA Fabric Manager
repo_domain = "com"
repo_domain = "cn" if node['cluster']['region'].start_with?("cn-")
repo_uri = node['cluster']['nvidia']['fabricmanager']['repository_uri'].gsub('_domain_', repo_domain)
add_package_repository(
  "nvidia-fm-repo",
  repo_uri,
  "#{repo_uri}/#{node['cluster']['nvidia']['fabricmanager']['repository_key']}",
  "/"
)

if platform?('ubuntu')
  # For ubuntu, CINC17 apt-package resources need full versions for `version`
  execute "install_fabricmanager_for_ubuntu" do
    command "apt -y install #{node['cluster']['nvidia']['fabricmanager']['package']}=#{node['cluster']['nvidia']['fabricmanager']['version']} "\
            "&& apt-mark hold #{node['cluster']['nvidia']['fabricmanager']['package']}"
    retries 3
    retry_delay 5
  end
else
  package node['cluster']['nvidia']['fabricmanager']['package'] do
    version node['cluster']['nvidia']['fabricmanager']['version']
    action %i(install lock)
  end
end

remove_package_repository("nvidia-fm-repo")
