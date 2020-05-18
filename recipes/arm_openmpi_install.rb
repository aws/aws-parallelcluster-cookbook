
# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: arm_openmpi_install
#
# Copyright 2013-2015 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.


return if node['conditions']['ami_bootstrapped'] || !arm_instance?

case node['platform_family']
when 'amazon'
  if node['platform_version'].to_i == 2
    package 'openmpi-devel' do
      retries 10
      retry_delay 5
    end
    # The above package creates the modulefile in /etc/modulefiles/mpi/openmpi-aarch64. Add
    # /etc/modulefiles/mpi to the default MODULEPATH so that the module can be used via
    # `module load openmpi-aarch64`.
    append_if_no_line "append mpi modulefiles line" do
      path "#{node['cfncluster']['moduleshome']}/init/.modulespath"
      line "/etc/modulefiles/mpi"
    end
  else
    Chef::Log.Info("ARM instances are currently only supported for Amazon Linux 2")
  end
when 'debian'
  package %w[libopenmpi-dev openmpi-bin openmpi-doc] do
    retries 10
    retry_delay 5
  end
else
  Chef::Log.Info("ARM instances are currently only supported for Amazon Linux 2, Ubuntu1604, and Ubuntu1804")
end
