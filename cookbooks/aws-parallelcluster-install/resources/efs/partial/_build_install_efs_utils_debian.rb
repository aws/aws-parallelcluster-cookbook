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

action :build_install_efs_utils do
  package_name = "amazon-efs-utils"
  efs_utils_tarball = node['cluster']['efs_utils']['tarball_path']

  # Do not install efs-utils if a same or newer version is already installed.
  return if Gem::Version.new(get_package_version(package_name)) >= Gem::Version.new(node['cluster']['efs_utils']['version'])

  # On Ubuntu, amazon-efs-utils and stunnel are installed from source
  # Because their OS repos do not have amazon-efs-utils and new stunnel
  # Get EFS Utils tarball
  remote_file efs_utils_tarball do
    source node['cluster']['efs_utils']['url']
    mode '0644'
    retries 3
    retry_delay 5
    checksum node['cluster']['efs_utils']['sha256']
    action :create_if_missing
  end

  # Install EFS Utils following https://docs.aws.amazon.com/efs/latest/ug/installing-amazon-efs-utils.html
  bash "install efs utils" do
    cwd node['cluster']['sources_dir']
    code <<-EFSUTILSINSTALL
      set -e
      tar xf #{efs_utils_tarball}
      cd efs-utils-#{node['cluster']['efs_utils']['version']}
      ./build-deb.sh
      apt-get -y install ./build/amazon-efs-utils*deb
    EFSUTILSINSTALL
  end
end
