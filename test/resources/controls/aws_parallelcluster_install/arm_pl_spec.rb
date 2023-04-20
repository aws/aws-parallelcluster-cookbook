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

control 'arm_pl_installed' do
  title "Check ARM Performance libraries installation"

  only_if { os_properties.arm? && !os_properties.virtualized? }

  describe bash("unset MODULEPATH && source /etc/profile.d/modules.sh && module load armpl") do
    its('exit_status') { should eq(0) }
  end

  arm_version = node['cluster']['armpl']['major_minor_version']
  arm_pl_installation = "armpl_#{arm_version}_gcc-9.3"
  test_software = "fftw_dft_r2c_1d_c_example"

  describe bash("sudo bash -c 'unset MODULEPATH && source /etc/profile.d/modules.sh && module load armpl && cd /opt/arm/armpl/#{arm_version}.0/#{arm_pl_installation}/examples &&  \
    gcc -c -I/opt/arm/armpl/#{arm_version}.0/#{arm_pl_installation}/include #{test_software}.c -o #{test_software}.o && \
    gcc #{test_software}.o -L/opt/arm/armpl/#{arm_version}.0/#{arm_pl_installation}/lib -o #{test_software}.exe -larmpl_lp64 -lm && \
    ./#{test_software}.exe'") do
    its('exit_status') { should eq(0) }
    its('stdout') { should match /ARMPL example: FFT of a real sequence using fftw_plan_dft_r2c_1d/ }
  end
end
