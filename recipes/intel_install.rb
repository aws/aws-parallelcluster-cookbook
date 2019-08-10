#
# Cookbook Name:: aws-parallelcluster
# Recipe:: intel_install
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

bash "install intel hpc platform" do
  cwd node['cfncluster']['sources_dir']
  code <<-INTEL
    set -e
    yum-config-manager --add-repo http://yum.repos.intel.com/hpc-platform/el7/setup/intel-hpc-platform.repo
    rpm --import http://yum.repos.intel.com/hpc-platform/el7/setup/PUBLIC_KEY.PUB
    yum -y install intel-hpc-platform-*
  INTEL
  creates '/etc/intel-hpc-platform-release'
end

bash "install intel psxe" do
  cwd node['cfncluster']['sources_dir']
  code <<-INTEL
    set -e
    rpm --import https://yum.repos.intel.com/2019/setup/RPM-GPG-KEY-intel-psxe-runtime-2019
    yum -y install https://yum.repos.intel.com/2019/setup/intel-psxe-runtime-2019-reposetup-1-0.noarch.rpm
    yum -y install intel-psxe-runtime
  INTEL
  creates '/opt/intel/psxe_runtime'
end

bash "install intel python" do
  cwd node['cfncluster']['sources_dir']
  code <<-INTEL
    set -e
    yum-config-manager --add-repo https://yum.repos.intel.com/intelpython/setup/intelpython.repo
    yum -y install intelpython2 intelpython3
  INTEL
  creates '/opt/intel/intelpython2'
end
