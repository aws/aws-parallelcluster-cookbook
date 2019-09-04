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

intelmpi_modulefile = "#{node['cfncluster']['modulefile_dir']}/intelmpi/#{node['cfncluster']['intelmpi']['version']}"
intelmpi_installer = "#{node['cfncluster']['sources_dir']}/intel_mpi.sh"

# Get intelmpi installer
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
    ./intel_mpi.sh install -check_efa 0 -version #{node['cfncluster']['intelmpi']['version']}
    cp #{node['cfncluster']['intelmpi']['modulefile']} #{intelmpi_modulefile}
  INTELMPI
  creates '/opt/intel/impi'
end
