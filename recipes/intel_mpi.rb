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

intelmpi_modulefile = "/opt/intel/impi/#{node['cfncluster']['intelmpi']['version']}/intel64/modulefiles/intelmpi"
intelmpi_installer = "#{node['cfncluster']['sources_dir']}/l_mpi_#{node['cfncluster']['intelmpi']['version']}.tgz"

# fetch intelmpi installer script
remote_file intelmpi_installer do
  source node['cfncluster']['intelmpi']['url']
  mode '0744'
  retries 3
  retry_delay 5
  not_if { ::File.exist?("/opt/intel/impi/#{node['cfncluster']['intelmpi']['version']}") }
end

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

append_if_no_line "append intel modules file dir to modules conf" do
  path "#{node['cfncluster']['moduleshome']}/init/.modulespath"
  line "/opt/intel/impi/#{node['cfncluster']['intelmpi']['version']}/intel64/modulefiles/"
end

execute "rename intel mpi modules file name" do
  command "mv #{node['cfncluster']['intelmpi']['modulefile']} #{intelmpi_modulefile}"
  creates intelmpi_modulefile.to_s
end
