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
  only_if { !os_properties.ubuntu2204? }
  only_if { os_properties.arm? && !os_properties.on_docker? }

  armpl_major_minor_version = node['cluster']['armpl']['major_minor_version']
  armpl_version = node['cluster']['armpl']['version']
  gcc_major_minor_version = node['cluster']['armpl']['gcc']['major_minor_version']

  armpl_module_general_name = "armpl/#{armpl_version}"
  armpl_module_name = "armpl/#{armpl_version}_gcc-#{gcc_major_minor_version}"
  gcc_module_name = "armpl/gcc-#{gcc_major_minor_version}"

  setup = "unset MODULEPATH && source /etc/profile.d/modules.sh"

  describe bash("#{setup} && module load #{armpl_module_general_name} && module list") do
    its('exit_status') { should eq(0) }
    its('stderr') { should_not be_empty }

    its('stderr') { should match /#{armpl_module_general_name}/ }
    its('stderr') { should match /#{armpl_module_name}/ }
    its('stderr') { should match /#{gcc_module_name}/ }
  end

  describe bash("ls /opt/arm/#{armpl_module_general_name}/arm-performance-libraries_#{armpl_major_minor_version}_gcc-#{gcc_major_minor_version}/license_terms") do
    its('stdout') { should include 'license_agreement.txt' }
    its('stdout') { should include 'third_party_licenses.txt' }
  end

  arm_version = node['cluster']['armpl']['major_minor_version']
  arm_pl_installation = "armpl_#{arm_version}_gcc-9.3"
  test_software = "fftw_dft_r2c_1d_c_example"

  scl_centos7 = "scl enable devtoolset-8" if os_properties.centos?

  describe bash("#{setup} && module load #{armpl_module_general_name} && "\
                "cd /opt/arm/armpl/#{armpl_version}/armpl_#{armpl_major_minor_version}_gcc-#{gcc_major_minor_version}/examples && "\
                "make clean && #{scl_centos7} make") do
    its('exit_status') { should eq(0) }
    its('stdout') { should match /testing: no example difference files were generated/i }
    its('stdout') { should match /test passed ok/i }
  end

  describe bash("sudo bash -c 'unset MODULEPATH && source /etc/profile.d/modules.sh && module load armpl && cd /opt/arm/armpl/#{arm_version}.0/#{arm_pl_installation}/examples &&  \
    gcc -c -I/opt/arm/armpl/#{arm_version}.0/#{arm_pl_installation}/include #{test_software}.c -o #{test_software}.o && \
    gcc #{test_software}.o -L/opt/arm/armpl/#{arm_version}.0/#{arm_pl_installation}/lib -o #{test_software}.exe -larmpl_lp64 -lm && \
    ./#{test_software}.exe'") do
    its('exit_status') { should eq(0) }
    its('stdout') { should match /ARMPL example: FFT of a real sequence using fftw_plan_dft_r2c_1d/ }
  end
end

control 'tag:install_arm_pl_gcc_installed' do
  title "Check ARM Performance libraries installation"
  only_if { !os_properties.ubuntu2204? }
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
