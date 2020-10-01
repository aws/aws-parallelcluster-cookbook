# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: efa_install
#
# Copyright 2013-2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

efa_tarball = "#{node['cfncluster']['sources_dir']}/aws-efa-installer.tar.gz"

# Get EFA Installer
remote_file efa_tarball do
  source node['cfncluster']['efa']['installer_url']
  mode '0644'
  retries 3
  retry_delay 5
  not_if { ::File.exist?(efa_tarball) }
end

# default openmpi installation conflicts with new install
# new one is installed in /opt/amazon/efa/bin/
case node['platform_family']
when 'rhel', 'amazon'
  package %w[openmpi-devel openmpi] do
    action :remove
    not_if { ::Dir.exist?('/opt/amazon/efa') }
  end
when 'debian'
  package "libopenmpi-dev" do
    action :remove
    not_if { ::Dir.exist?('/opt/amazon/efa') }
  end
end

installer_options = "-y"
# efa-kmod currently unavailable for ARM instances
installer_options += " -k" if arm_instance?
# enable gpudirect support
installer_options += " -g" if efa_gdr_enabled?

bash "install efa" do
  cwd node['cfncluster']['sources_dir']
  code <<-EFAINSTALL
    set -e
    tar -xzf #{efa_tarball}
    cd aws-efa-installer
    ./efa_installer.sh #{installer_options}
  EFAINSTALL
  not_if { ::Dir.exist?('/opt/amazon/efa') && !efa_gdr_enabled?}
end
