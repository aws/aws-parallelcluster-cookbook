# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: intel_mpi
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

return unless node['conditions']['intel_mpi_supported']

intelmpi_modulefile = "#{node['cfncluster']['modulefile_dir']}/intelmpi/#{node['cfncluster']['intelmpi']['version']}"
intelmpi_installer = "#{node['cfncluster']['sources_dir']}/l_mpi_#{node['cfncluster']['intelmpi']['version']}.tgz"

# fetch intelmpi installer script
remote_file intelmpi_installer do
  source node['cfncluster']['intelmpi']['url']
  mode '0744'
  retries 3
  retry_delay 5
  not_if { ::File.exist?(intelmpi_installer) }
end

directory "#{node['cfncluster']['modulefile_dir']}/intelmpi"

bash "install intel mpi" do
  cwd node['cfncluster']['sources_dir']
  code <<-INTELMPI
    set -e
    tar -xf l_mpi_#{node['cfncluster']['intelmpi']['version']}.tgz
    cd l_mpi_#{node['cfncluster']['intelmpi']['version']}/
    ./install.sh -s silent.cfg --accept_eula
    mv rpm/EULA.txt /opt/intel/impi/#{node['cfncluster']['intelmpi']['version']}
    cd ..
    rm -rf l_mpi_#{node['cfncluster']['intelmpi']['version']}*
  INTELMPI
  creates "/opt/intel/impi/#{node['cfncluster']['intelmpi']['version']}"
end

bash "create modulefile" do
  cwd node['cfncluster']['modulefile_dir']
  code <<-MODULEFILE
    set -e
    cp #{node['cfncluster']['intelmpi']['modulefile']} #{intelmpi_modulefile}
  MODULEFILE
  creates intelmpi_modulefile
end

if (node['platform'] == 'centos' && node['platform_version'].to_i >= 7) \
  || node['platform'] == 'amazon'
  execute 'yum-config-manager_skip_if_unavail_intel_mpi' do
    command "yum-config-manager --save --setopt=intel-mpi.skip_if_unavailable=true"
  end
end
