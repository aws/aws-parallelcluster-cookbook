# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: efs_mount
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

# Get shared_dir path and mount EFS filesystem
efs_shared_dir =  node['cfncluster']['cfn_efs_shared_dir'].split(',')[0]

# Check to see if EFS is created
if efs_shared_dir != "NONE"

  # Path needs to be fully qualified, for example "shared/temp" becomes "/shared/temp"
  efs_shared_dir = "/#{efs_shared_dir}" unless efs_shared_dir.start_with?('/')

  # Create the EFS shared directory
  directory efs_shared_dir do
    owner 'root'
    group 'root'
    mode '1777'
    recursive true
    action :create
  end

  # Mount EFS over NFS
  mount efs_shared_dir do
    device "#{node['cfncluster']['cfn_efs']}.efs.#{node['cfncluster']['cfn_region']}.#{node['cfncluster']['aws_domain']}:/"
    fstype 'nfs4'
    options 'nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=30,retrans=2,noresvport,_netdev'
    dump 0
    pass 0
    action %i[mount enable]
    retries 3
    retry_delay 5
  end

  # Make sure EFS shared directory permissions are correct
  directory efs_shared_dir do
    owner 'root'
    group 'root'
    mode '1777'
  end
end
