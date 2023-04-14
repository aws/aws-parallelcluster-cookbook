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

  describe bash("sudo bash -c 'unset MODULEPATH && source /etc/profile.d/modules.sh && module load armpl && cd /opt/arm/armpl/21.0.0/armpl_21.0_gcc-9.3/examples &&  \
    gcc -c -I/opt/arm/armpl/21.0.0/armpl_21.0_gcc-9.3/include fftw_dft_r2c_1d_c_example.c -o fftw_dft_r2c_1d_c_example.o && \
    gcc fftw_dft_r2c_1d_c_example.o -L/opt/arm/armpl/21.0.0/armpl_21.0_gcc-9.3/lib -o fftw_dft_r2c_1d_c_example.exe -larmpl_lp64 -lm && \
    ./fftw_dft_r2c_1d_c_example.exe'") do
    its('exit_status') { should eq(0) }
    its('stdout') { should match /ARMPL example: FFT of a real sequence using fftw_plan_dft_r2c_1d/ }
  end
end
