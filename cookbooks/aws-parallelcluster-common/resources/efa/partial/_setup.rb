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

efa_tarball = "#{node['cluster']['sources_dir']}/aws-efa-installer.tar.gz"

action :setup do
  action_check_efa_support
  if node['cluster']['efa_supported']
    if efa_installed? && !::File.exist?(efa_tarball)
      Chef::Log.warn("Existing EFA version differs from the one shipped with ParallelCluster. Skipping ParallelCluster EFA installation and configuration.")
      return
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
    package %w(environment-modules) do
      retries 3
      retry_delay 5
    end

    action_download_and_install
  end
end

action :download_and_install do
  # Get EFA Installer
  efa_installer_url = "https://efa-installer.amazonaws.com/aws-efa-installer-#{node['cluster']['efa']['installer_version']}.tar.gz"
  remote_file efa_tarball do
    source efa_installer_url
    mode '0644'
    retries 3
    retry_delay 5
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
    not_if { efa_installed? || virtualized? }
  end
end

action :check_efa_support do
  node.default['cluster']['efa_supported'] = true
end
