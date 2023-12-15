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

#
# EFA setup: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/efa-start.html
#

property :efa_version, String, default: '1.29.1'
property :efa_checksum, String, default: '178b263b8c25845b63dc93b25bcdff5870df5204ec509af26f43e8d283488744'

action :setup do
  if efa_installed? && !::File.exist?(efa_tarball)
    log 'efa installed' do
      message 'Existing EFA version differs from the one shipped with ParallelCluster. Skipping ParallelCluster EFA installation and configuration.'
      level :warn
    end
    return
  end

  directory node['cluster']['sources_dir'] do
    recursive true
  end

  # remove conflicting packages
  # default openmpi installation conflicts with new install
  # new one is installed in /opt/amazon/efa/bin/
  package conflicting_packages do
    action :remove
    not_if { efa_installed? }
  end

  # update repos and install prerequisite packages
  package_repos 'update package repos' do
    action :update
  end
  package prerequisites do
    retries 3
    retry_delay 5
  end

  action_download_and_install
end

action :download_and_install do
  # Get EFA Installer
  efa_installer_url = "https://efa-installer.amazonaws.com/aws-efa-installer-#{new_resource.efa_version}.tar.gz"
  remote_file efa_tarball do
    source efa_installer_url
    mode '0644'
    retries 3
    retry_delay 5
    checksum new_resource.efa_checksum
    action :create_if_missing
  end

  installer_options = "-y"
  # skip efa-kmod installation on not supported platforms
  installer_options += " -k" unless efa_supported?

  bash "install efa" do
    cwd node['cluster']['sources_dir']
    code <<-EFAINSTALL
      set -e
      tar -xzf #{efa_tarball}
      cd aws-efa-installer
      ./efa_installer.sh #{installer_options}
      rm -rf #{node['cluster']['sources_dir']}/aws-efa-installer
    EFAINSTALL
    not_if { efa_installed? || on_docker? }
  end
end

action :configure do
  node.default['cluster']['efa']['installer_version'] = new_resource.efa_version
  node_attributes 'dump node attributes'
end

action_class do
  def efa_installed?
    dir_exist = ::Dir.exist?('/opt/amazon/efa')
    if dir_exist
      modinfo_efa_stdout = shell_out("modinfo efa").stdout
      efa_installed_packages_file = shell_out("cat /opt/amazon/efa_installed_packages").stdout
      Chef::Log.info("`/opt/amazon/efa` directory already exists. \nmodinfo efa stdout: \n#{modinfo_efa_stdout} \nefa_installed_packages_file_content: \n#{efa_installed_packages_file}")
    end
    dir_exist
  end

  def efa_supported?
    true
  end

  def efa_tarball
    "#{node['cluster']['sources_dir']}/aws-efa-installer.tar.gz"
  end
end
