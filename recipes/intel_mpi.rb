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

env2 = "#{node['cfncluster']['sources_dir']}/env2"
intelmpi_modulefile = "#{node['cfncluster']['modulefile_dir']}/intelmpi/#{node['cfncluster']['intelmpi']['version']}"

cookbook_file 'intel_mpi.sh' do
  path "#{node['cfncluster']['sources_dir']}/intel_mpi.sh"
  user 'root'
  group 'root'
  mode '0744'
end

# Get env2
remote_file env2 do
  source node['cfncluster']['env2']['url']
  mode '0744'
  retries 3
  retry_delay 5
  not_if { ::File.exist?(env2) }
end

bash "install intel mpi" do
  cwd node['cfncluster']['sources_dir']
  code <<-INTELMPI
    ./intel_mpi.sh
  INTELMPI
  creates '/opt/intel'
end

directory "#{node['cfncluster']['modulefile_dir']}/intelmpi"

bash "create intelmpi modulefile" do
  cwd node['cfncluster']['sources_dir']
  code <<-INTELMPI
    echo "#%Module" > #{intelmpi_modulefile}
    ./env2 -from bash -to modulecmd "#{node['cfncluster']['mpivars']}" >> #{intelmpi_modulefile}
  INTELMPI
  creates intelmpi_modulefile
end