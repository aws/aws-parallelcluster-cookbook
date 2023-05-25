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

action :install_utils do
  package_repos 'update package repositories' do
    action :update
  end

  package prerequisites do
    retries 3
    retry_delay 5
  end

  directory node['cluster']['sources_dir'] do
    recursive true
  end

  return if redhat_ubi?

  package_name = "amazon-efs-utils"
  package_version = new_resource.efs_utils_version
  efs_utils_tarball = "#{node['cluster']['sources_dir']}/efs-utils-#{package_version}.tar.gz"
  efs_utils_url = "https://github.com/aws/efs-utils/archive/v#{package_version}.tar.gz"

  # Do not install efs-utils if a same or newer version is already installed.
  return if already_installed?(package_name, package_version)

  # On all OSes but Amazon Linux 2, amazon-efs-utils and stunnel are installed from source,
  # because their OS repos do not have amazon-efs-utils and new stunnel

  # Get EFS Utils tarball
  remote_file efs_utils_tarball do
    source efs_utils_url
    mode '0644'
    retries 3
    retry_delay 5
    checksum new_resource.efs_utils_checksum
    action :create_if_missing
  end

  # Install EFS Utils following https://docs.aws.amazon.com/efs/latest/ug/installing-amazon-efs-utils.html
  bash "install efs utils" do
    cwd node['cluster']['sources_dir']
    code install_script_code(efs_utils_tarball, package_name, package_version)
  end
end
