# frozen_string_literal: true

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

provides :intel_hpc

unified_mode true
default_action :setup

action :setup do
  # do nothing
end

action :configure do
  return unless intel_hpc_supported? && (node['cluster']['install_intel_base_toolkit'] == "true" || node['cluster']['install_intel_hpc_toolkit'] == "true" || node['cluster']['install_intel_python'] == "true")

  base_toolkit_version = "2023.2.0.49397"
  base_toolkit_name = "l_BaseKit_p_#{base_toolkit_version}_offline.sh"
  base_toolkit_url = "https://registrationcenter-download.intel.com/akdlm/IRC_NAS/992857b9-624c-45de-9701-f6445d845359/#{base_toolkit_name}"
  hpc_toolkit_version = "2023.2.0.49440"
  hpc_toolkit_name = "l_HPCKit_p_#{hpc_toolkit_version}_offline.sh"
  hpc_toolkit_url = "https://registrationcenter-download.intel.com/akdlm/IRC_NAS/0722521a-34b5-4c41-af3f-d5d14e88248d/#{hpc_toolkit_name}"
  intel_python_version = "2023.2.0.49422"
  intel_python_name = "l_pythoni39_oneapi_p_#{intel_python_version}_offline.sh"
  intel_python_url = "https://registrationcenter-download.intel.com/akdlm/IRC_NAS/03aae3a8-623a-47cf-9655-5dd8fcf86430/#{intel_python_name}"
  # Below are critical security updates not included in the tookits:
  cpp_compiler_version = "2023.2.1.8"
  cpp_compiler_name = "l_dpcpp-cpp-compiler_p_#{cpp_compiler_version}_offline.sh"
  cpp_compiler_url = "https://registrationcenter-download.intel.com/akdlm/IRC_NAS/ebf5d9aa-17a7-46a4-b5df-ace004227c0e/#{cpp_compiler_name}"
  fortran_compiler_version = "2023.2.1.8"
  fortran_compiler_name = "l_fortran-compiler_p_#{fortran_compiler_version}_offline.sh"
  fortran_compiler_url = "https://registrationcenter-download.intel.com/akdlm/IRC_NAS/0d65c8d4-f245-4756-80c4-6712b43cf835/#{fortran_compiler_name}"

  intel_offline_installer_dir = '/opt/intel/offlineInstaller'

  directory intel_offline_installer_dir do
    recursive true
  end

  if node['cluster']['install_intel_base_toolkit'] == "true"
    install_intel_software "Install Intel Base Toolkit" do
      software_name base_toolkit_name
      software_url base_toolkit_url
      intel_offline_installer_dir intel_offline_installer_dir
    end
    install_intel_software "Critical Update for Intel oneAPI DPC++/C++ Compiler" do
      software_name cpp_compiler_name
      software_url cpp_compiler_url
      intel_offline_installer_dir intel_offline_installer_dir
    end
  end
  if node['cluster']['install_intel_hpc_toolkit'] == "true"
    install_intel_software "Intel OneAPI HPC Toolkits" do
      software_name hpc_toolkit_name
      software_url hpc_toolkit_url
      intel_offline_installer_dir intel_offline_installer_dir
    end
    install_intel_software "Critical Update for Intel Fortran Compiler & Intel Fortran Compiler Classic" do
      software_name fortran_compiler_name
      software_url fortran_compiler_url
      intel_offline_installer_dir intel_offline_installer_dir
    end
  end
  if node['cluster']['install_intel_python'] == "true"
    install_intel_software "Install Intel Python" do
      software_name intel_python_name
      software_url intel_python_url
      intel_offline_installer_dir intel_offline_installer_dir
    end
  end
  bash "copy Intel modulefiles to MODULEPATH" do
    cwd "/opt/intel"
    code <<-INTEL
    set -e
    ./modulefiles-setup.sh --output-dir="/usr/share/Modules/modulefiles/intel"
    INTEL
  end
end

def intel_hpc_supported?
  !arm_instance?
end
