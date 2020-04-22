# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: fsx_mount
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

fsx_shared_dir = node['cfncluster']['cfn_fsx_options'].split(',')[0]

# Check to see if FSx is created
if fsx_shared_dir != "NONE"

  # Path needs to be fully qualified, for example "shared/temp" becomes "/shared/temp"
  fsx_shared_dir = "/" + fsx_shared_dir unless fsx_shared_dir.start_with?("/")

  # Create the shared directories
  directory fsx_shared_dir do
    owner 'root'
    group 'root'
    mode '1777'
    action :create
  end

  require 'chef/mixin/shell_out'
  proxy_prefix = node['cfncluster']['cfn_proxy'] != 'NONE'? "export HTTP_PROXY=#{node['cfncluster']['cfn_proxy']} && export HTTPS_PROXY=#{node['cfncluster']['cfn_proxy']} && " : ""
  mountname = shell_out!("#{proxy_prefix}#{node['cfncluster']['cookbook_virtualenv_path']}/bin/aws fsx --region #{node['cfncluster']['cfn_region']} describe-file-systems --file-system-ids #{node['cfncluster']['cfn_fsx_fs_id']} --query 'FileSystems[0].LustreConfiguration.MountName' --output text", :user=>'root').stdout.strip

  mount_options = %w[defaults _netdev flock user_xattr noatime]

  mount_options.push(%w[noauto x-systemd.automount]) if node['init_package'] == 'systemd'

  # Mount FSx over NFS
  mount fsx_shared_dir do
    device "#{node['cfncluster']['cfn_fsx_fs_id']}.fsx.#{node['cfncluster']['cfn_region']}.#{node['cfncluster']['aws_domain']}@tcp:/#{mountname}"
    fstype 'lustre'
    dump 0
    pass 0
    options mount_options
    action %i[mount enable]
    retries 3
    retry_delay 5
  end

  # Make sure permission is correct
  directory fsx_shared_dir do
    owner 'root'
    group 'root'
    mode '1777'
  end
end
