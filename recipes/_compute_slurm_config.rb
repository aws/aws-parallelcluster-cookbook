#
# Cookbook Name:: cfncluster
# Recipe:: _compute_slurm_config
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

# Mount /opt/slurm over NFS
nfs_master = node['cfncluster']['cfn_master'].split('.')[0]
mount '/opt/slurm' do
  device "#{nfs_master}:/opt/slurm"
  fstype "nfs"
  options 'hard,intr,noatime,vers=3,_netdev'
  action [:mount, :enable]
end

service "slurm" do
  supports restart: false
  action [:enable]
end
