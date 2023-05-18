# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: intel_mpi
#
# Copyright:: 2013-2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

intelmpi_supported = !arm_instance?
intelmpi_version = '2021.9.0'

node.default['conditions']['intel_mpi_supported'] = intelmpi_supported
node.default['cluster']['intelmpi']['version'] = intelmpi_version

node_attributes "dump node attributes"

return unless intelmpi_supported

intelmpi_full_version = "#{intelmpi_version}.43482"
intelmpi_installation_path = "/opt/intel/mpi/#{intelmpi_version}"
intelmpi_installer = "l_mpi_oneapi_p_#{intelmpi_full_version}_offline.sh"
intelmpi_installer_path = "#{node['cluster']['sources_dir']}/#{intelmpi_installer}"
intelmpi_installer_url = "https://#{node['cluster']['region']}-aws-parallelcluster.s3.#{node['cluster']['region']}.#{aws_domain}/archives/impi/#{intelmpi_installer}"
intelmpi_qt_version = '6.4.2'

# Prerequisite for module install
modules 'Prerequisite: Environment modules'
directory node['cluster']['sources_dir'] do
  recursive true
end

# fetch intelmpi installer script
remote_file intelmpi_installer_path do
  source intelmpi_installer_url
  mode '0744'
  retries 3
  retry_delay 5
  not_if { ::File.exist?(intelmpi_installation_path.to_s) }
end

bash "install intel mpi" do
  cwd node['cluster']['sources_dir']
  code <<-INTELMPI
    set -e
    chmod +x #{intelmpi_installer}
    ./#{intelmpi_installer} --remove-extracted-files yes -a --silent --eula accept --install-dir /opt/intel
    rm -f #{intelmpi_installer}
  INTELMPI
  creates intelmpi_installation_path.to_s
end

modules 'append intel modules file dir to modules conf' do
  line "#{intelmpi_installation_path}/modulefiles/"
  action :append_to_config
end

intelmpi_modulefile_from = "#{intelmpi_installation_path}/modulefiles/mpi"
intelmpi_modulefile_to   = "#{intelmpi_installation_path}/modulefiles/intelmpi"

execute "rename intel mpi modules file name" do
  command "mv #{intelmpi_modulefile_from} #{intelmpi_modulefile_to}"
  creates intelmpi_modulefile_to.to_s
end

# Add Qt source file
template "#{intelmpi_installation_path}/qt_source_code.txt" do
  source 'intel_mpi/qt_source_code.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    aws_region: node['cluster']['region'],
    aws_domain: node['cluster']['aws_domain'],
    intelmpi_qt_version: intelmpi_qt_version
  )
end
