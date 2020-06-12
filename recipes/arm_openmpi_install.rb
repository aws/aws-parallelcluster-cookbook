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

openmpi_modules_dir = "#{node['cfncluster']['moduleshome']}/modulefiles/openmpi"

case node['platform_family']
when 'amazon'
  if node['platform_version'].to_i == 2
    package 'openmpi-devel' do
      retries 3
      retry_delay 5
    end
    # The above package creates the modulefile in /etc/modulefiles/mpi/openmpi-aarch64.
    # Create a symbolic link from $MODULESHOME/modulefiles/openmpi/${VERSION} to this file
    # to more closely mimic the user experience provided on x86_64 AMIs.
    directory openmpi_modules_dir do
      mode '755'
      owner 'root'
      group 'root'
      action :create
    end
    openmpi_version = "4.0.1"
    link "#{openmpi_modules_dir}/#{openmpi_version}" do
      to "/etc/modulefiles/mpi/openmpi-aarch64"
    end
  else
    Chef::Log.Info("ARM instances are currently only supported for Amazon Linux 2")
  end
when 'debian'
  package %w[environment-modules libopenmpi-dev openmpi-bin openmpi-doc] do
    retries 3
    retry_delay 5
  end
  # Create a dummy modulefile

  openmpi_version = if node['platform_version'] == "18.04"
                      "2.1.1"
                    else
                      "1.10.2"
                    end
  directory openmpi_modules_dir do
    mode '755'
    owner 'root'
    group 'root'
    action :create
  end
  cookbook_file "#{openmpi_modules_dir}/#{openmpi_version}" do
    source 'openmpi-modulefile-via-alternatives'
    owner 'root'
    group 'root'
    mode '0644'
    action :create
  end
else
  Chef::Log.Info("ARM instances are currently only supported for Amazon Linux 2, Ubuntu1604, and Ubuntu1804")
end
