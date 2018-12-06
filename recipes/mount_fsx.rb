#
# Cookbook Name:: aws-parallelcluster
# Recipe:: mount_fsx
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

fsx_shared_dir = "/" + node['cfncluster']['cfn_fsx_shared_dir'].split(',')[0]
fsx_fs_id = node['cfncluster']['cfn_fsx']

# Check to see if FSx is created
if fsx_shared_dir != "/NONE"
  # Create the shared directories
  directory fsx_shared_dir do
    owner 'root'
    group 'root'
    mode '1777'
    action :create
  end

  # Download lustre mount drivers
  execute "download_lustre_drivers_1" do
    command 'wget https://downloads.whamcloud.com/public/lustre/lustre-2.10.5/el7.5.1804/client/RPMS/x86_64/kmod-lustre-client-2.10.5-1.el7.x86_64.rpm'
    action :run
  end

  execute "download_lustre_drivers_2" do
    command 'wget https://downloads.whamcloud.com/public/lustre/lustre-2.10.5/el7.5.1804/client/RPMS/x86_64/lustre-client-2.10.5-1.el7.x86_64.rpm'
    action :nothing
    subscribes :run, 'execute[download_lustre_drivers_1]', :immediately
  end

  # Install lustre mount drivers
  execute "install_lustre_drivers" do
    command 'sudo yum localinstall -y *lustre-client-2.10.5*.rpm'
    action :nothing
    subscribes :run, 'execute[download_lustre_drivers_2]', :immediately
  end

  # Mount filesystem via lustre mount
  execute "mount_drive" do
    command "mount -t lustre #{fsx_fs_id}.fsx.#{node['cfncluster']['cfn_region']}.amazonaws.com@tcp:/fsx #{fsx_shared_dir}"
    action :nothing
    subscribes :run, 'execute[install_lustre_drivers]', :immediately
  end

  # Make sure permission is correct
  directory fsx_shared_dir do
    owner 'root'
    group 'root'
    mode '1777'
  end
end
