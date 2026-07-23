# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

driver_version = node['cluster']['nvidia']['driver_version']
cuda_version_dashed = node['cluster']['nvidia']['cuda']['version'].split('.')[0, 2].join('-')
local_repo_platform =
  if os_properties.alinux?
    'amzn2023'
  elsif os_properties.ubuntu?
    "ubuntu#{os.release.delete('.')}"
  else
    "rhel#{os.release.to_i}"
  end
nvidia_local_repo_packages = [
  "nvidia-driver-local-repo-#{local_repo_platform}-#{driver_version}",
  "cuda-repo-#{local_repo_platform}-#{cuda_version_dashed}-local",
]

# No tag:install_ prefix on purpose: repos only exist between the nvidia_repo
# add/remove actions, so full install builds must not select this control.
control 'tag:nvidia_local_repos_added' do
  only_if do
    !os_properties.on_docker? &&
      (node['cluster']['nvidia']['enabled'] == 'yes' || node['cluster']['nvidia']['enabled'] == true)
  end

  nvidia_local_repo_packages.each do |repo_package|
    describe package(repo_package) do
      it { should be_installed }
    end

    describe directory("/var/#{repo_package}") do
      it { should exist }
    end
  end
end

control 'tag:install_nvidia_local_repos_removed' do
  only_if { !instance.custom_ami? }

  nvidia_local_repo_packages.each do |repo_package|
    describe package(repo_package) do
      it { should_not be_installed }
    end

    describe directory("/var/#{repo_package}") do
      it { should_not exist }
    end
  end
end
