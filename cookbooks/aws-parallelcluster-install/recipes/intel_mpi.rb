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

return unless node['conditions']['intel_mpi_supported']

intelmpi_installation_path = "/opt/intel/mpi/#{node['cluster']['intelmpi']['version']}"
intelmpi_modulefile = "#{intelmpi_installation_path}/modulefiles/intelmpi"
intelmpi_installer = "l_mpi_oneapi_p_#{node['cluster']['intelmpi']['full_version']}_offline.sh"
intelmpi_installer_path = "#{node['cluster']['sources_dir']}/#{intelmpi_installer}"
intelmpi_installer_url = "https://#{node['cluster']['region']}-aws-parallelcluster.s3.#{node['cluster']['region']}.#{aws_domain}/archives/impi/#{intelmpi_installer}"

# Prerequisite for module install
package %w(environment-modules) do
  retries 3
  retry_delay 5
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

append_if_no_line "append intel modules file dir to modules conf #{node['cluster']['modulepath_config_file']}" do
  path node['cluster']['modulepath_config_file']
  line "#{intelmpi_installation_path}/modulefiles/"
end

execute "rename intel mpi modules file name" do
  command "mv #{node['cluster']['intelmpi']['modulefile']} #{intelmpi_modulefile}"
  creates intelmpi_modulefile.to_s
end

# Add Qt source file
template "#{intelmpi_installation_path}/qt_source_code.txt" do
  source 'intel_mpi/qt_source_code.erb'
  owner 'root'
  group 'root'
  mode '0644'
end
