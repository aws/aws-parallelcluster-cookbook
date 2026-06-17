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

control 'tag:install_arm_pl_installed' do
  title "Check ARM Performance libraries installation"
  only_if { os_properties.arm? && !os_properties.on_docker? }

  armpl_version = node['cluster']['armpl']['version']
  gcc_major_minor_version = node['cluster']['armpl']['gcc']['major_minor_version']

  armpl_module_general_name = "armpl/#{armpl_version}"
  # ArmPL's gcc module name uses a 3-segment version: a 2-part version (24.10) is
  # padded to 24.10.0, while a 3-part version (26.01.1) is used as-is.
  armpl_module_version = armpl_version.split('.').length < 3 ? "#{armpl_version}.0" : armpl_version
  armpl_module_name = "armpl/#{armpl_module_version}_gcc"
  gcc_module_name = "armpl/gcc-#{gcc_major_minor_version}"

  armpl_script_dir = "/opt/arm/#{armpl_module_general_name}/arm-performance-libraries_#{armpl_version}_gcc"
  armpl_install_dir = "/opt/arm/#{armpl_module_general_name}/armpl_#{armpl_version}_gcc"

  setup = "unset MODULEPATH && source /etc/profile.d/modules.sh"

  describe bash("#{setup} && module load #{armpl_module_general_name} && module list") do
    its('exit_status') { should eq(0) }
    its('stderr') { should_not be_empty }

    its('stderr') { should match /#{armpl_module_general_name}/ }
    its('stderr') { should match /#{armpl_module_name}/ }
    its('stderr') { should match /#{gcc_module_name}/ }
  end

  describe bash("ls #{armpl_script_dir}/license_terms") do
    its('stdout') { should include 'license_agreement.txt' }
    its('stdout') { should include 'third_party_licenses.txt' }
  end

  test_software = "fftw_dft_r2c_1d_c_example"

  describe bash("#{setup} && module load #{armpl_module_general_name} && "\
                "cd #{armpl_install_dir}/examples_lp64 && "\
                "make clean && make") do
    its('exit_status') { should eq(0) }
    its('stdout') { should match /testing: no example difference files were generated/i }
    its('stdout') { should match /test passed ok/i }
  end

  describe bash("sudo bash -c 'unset MODULEPATH && source /etc/profile.d/modules.sh && module load armpl && cd #{armpl_install_dir}/examples_lp64 &&  \
    gcc -c -I#{armpl_install_dir}/include #{test_software}.c -o #{test_software}.o && \
    gcc #{test_software}.o -L#{armpl_install_dir}/lib -o #{test_software}.exe -larmpl_lp64 -lm && \
    ./#{test_software}.exe'") do
    its('exit_status') { should eq(0) }
    its('stdout') { should match /ARMPL example: FFT of a real sequence using fftw_plan_dft_r2c_1d/ }
  end
end

control 'tag:install_arm_pl_gcc_installed' do
  title "Check ARM Performance libraries installation"
  only_if { os_properties.arm? && !os_properties.on_docker? }

  gcc_major_minor_version = node['cluster']['armpl']['gcc']['major_minor_version']
  gcc_patch_version = node['cluster']['armpl']['gcc']['patch_version']
  gcc_version = "#{gcc_major_minor_version}.#{gcc_patch_version}"

  describe directory('/opt/arm/armpl/gcc') do
    it { should exist }
  end

  describe file("/opt/arm/armpl/gcc/#{gcc_version}/share/gcc-#{gcc_version}") do
    it { should exist }
    it { should be_executable }
  end
end
