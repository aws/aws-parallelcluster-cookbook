# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-test
# Recipe:: test_nvidia
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

return if (node['cluster']['base_os'] == 'centos7' && arm_instance?) || node['cluster']['os'].end_with?("-custom")

bash "check Nvidia drivers" do
  cwd Chef::Config[:file_cache_path]
  code <<-TEST
    expected_nvidia_driver_version="#{node['cluster']['nvidia']['driver_version']}"
    export PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/opt/aws/bin"

    echo "Testing Nvidia driver version"
    nvidia_driver_version=$(modinfo -F version nvidia)
    [[ "${nvidia_driver_version}" != "${expected_nvidia_driver_ver}" ]] && "ERROR Installed Nvidia driver version ${nvidia_driver_version} but expected ${expected_nvidia_driver_version}" && exit 1
    echo "Correctly installed Nvidia ${nvidia_driver_version}"

    echo "Testing CUDA installation with nvcc"
    cuda_ver="#{node['cluster']['nvidia']['cuda_version']}"
    export PATH=/usr/local/cuda-${cuda_ver}/bin:${PATH}
    export LD_LIBRARY_PATH=/usr/local/cuda-${cuda_ver}/lib64:${LD_LIBRARY_PATH}
    cuda_output=$(nvcc -V | grep -E -o "release [0-9]+.[0-9]+")
    [[ "${cuda_output}" != "release ${cuda_ver}" ]] && echo "ERROR Installed version ${cuda_output} but expected ${cuda_ver}" && exit 1
    echo "Correctly installed CUDA ${cuda_output}"
  TEST
end

bash "Check NVIDIA GdrCopy" do
  cwd Chef::Config[:file_cache_path]
  code <<-TEST
    expected_gdrcopy_version="#{node['cluster']['nvidia']['gdrcopy']['version']}"

    echo "Checking NVIDIA GdrCopy version"
    gdrcopy_version=$(modinfo -F version gdrdrv)
    [[ "${gdrcopy_version}" != "${expected_gdrcopy_version}" ]] && "ERROR Installed NVIDIA GdrCopy version ${gdrcopy_version} but expected ${expected_gdrcopy_version}" && exit 1
    echo "Correctly installed NVIDIA GdrCopy ${expected_gdrcopy_version}"

    #echo "Checking NVIDIA GdrCopy installation with copybw"
    #copybw
    #[[ $? != 0 ]] && "ERROR Installed NVIDIA GdrCopy is not working properly: copybw test failed" && exit 1
  TEST
end
