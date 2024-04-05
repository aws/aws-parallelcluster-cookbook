# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

control 'tag:install_intel_mpi_modules_file_dir_is_appended_to_modules_conf' do
  title "intel_mpi should be installed with the corresponding environment-modules"

  # Test only on head node since on compute nodes we mount an empty /opt/intel drive in kitchen tests that
  # overrides intel binaries.
  only_if { node['conditions']['intel_mpi_supported'] && instance.head_node? }

  modules_home = os_properties.ubuntu? ? "/usr/share/modules" : "/usr/share/Modules"
  modulepath_config_file = (os_properties.redhat? || os_properties.alinux2023?) ? '/etc/environment-modules/modulespath' : "#{modules_home}/init/.modulespath"

  describe file(modulepath_config_file) do
    it { should exist }
    its('content') { should match %r{/opt/intel/mpi/#{node['cluster']['intelmpi']['version']}/modulefiles/} }
  end
end

control 'tag:install_tag:config_intel_mpi_installed' do
  title "intel_mpi should be installed with the corresponding environment-modules"

  # Test only on head node since on compute nodes we mount an empty /opt/intel drive in kitchen tests that
  # overrides intel binaries.
  only_if { node['conditions']['intel_mpi_supported'] && instance.head_node? }

  describe bash("unset MODULEPATH && source /etc/profile.d/modules.sh && module load intelmpi && mpirun --help") do
    its('exit_status') { should eq(0) }
    its('stdout') { should match(/Version #{node['cluster']['intelmpi']['version'].split('.')[0..1].join(".")}/) }
  end
end
