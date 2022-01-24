# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: efa
#
# Copyright:: 2013-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

efa_tarball = "#{node['cluster']['sources_dir']}/aws-efa-installer.tar.gz"
efa_installed = efa_installed?

if efa_installed && !::File.exist?(efa_tarball)
  Chef::Log.warn("Existing EFA version differs from the one shipped with ParallelCluster. Skipping ParallelCluster EFA installation and configuration.")
  return
end

# Get EFA Installer
remote_file efa_tarball do
  source node['cluster']['efa']['installer_url']
  mode '0644'
  retries 3
  retry_delay 5
  not_if { ::File.exist?(efa_tarball) }
end

# default openmpi installation conflicts with new install
# new one is installed in /opt/amazon/efa/bin/
case node['platform_family']
when 'rhel', 'amazon'
  package %w(openmpi-devel openmpi) do
    action :remove
    not_if { efa_installed }
  end
when 'debian'
  package "libopenmpi-dev" do
    action :remove
    not_if { efa_installed }
  end
end

installer_options = "-y"
# skip efa-kmod installation on not supported platforms
installer_options += " -k" unless node['conditions']['efa_supported']

bash "install efa" do
  cwd node['cluster']['sources_dir']
  code <<-EFAINSTALL
    set -e
    tar -xzf #{efa_tarball}
    cd aws-efa-installer
    ./efa_installer.sh #{installer_options}
    rm -rf #{node['cluster']['sources_dir']}/aws-efa-installer
  EFAINSTALL
  not_if { efa_installed }
end
