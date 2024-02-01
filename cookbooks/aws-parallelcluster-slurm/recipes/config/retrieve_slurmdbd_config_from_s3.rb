# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-slurm
# Recipe:: retrieve_slurmdbd_config_from_s3
#
# Copyright:: 2013-2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# WARNING: Mountpoint for Amazon S3 is a tool that allows you to mount an S3 bucket as a file system.
# This is now GA, but it is still hosted on the AWS Labs repositories (https://github.com/awslabs/mountpoint-s3).
# This is considered fine for the external slurmdbd stack.
# A deeper evaluation would be required for further uses of this tool in AWS ParallelCluster.

bucket_name = node['slurmdbd_conf_bucket']
config_files = ["slurmdbd.conf", "slurm_external_slurmdbd.conf"]

config_files.each do |config_file|
  remote_object config_file do
    url "s3://#{bucket_name}/#{config_file}"
    destination "#{node['cluster']['slurm']['install_dir']}/etc/#{config_file}"
    sensitive true
    ignore_failure true
  end

  file "#{node['cluster']['slurm']['install_dir']}/etc/#{config_file}" do
    mode '0600'
    owner node['cluster']['slurm']['user']
    group node['cluster']['slurm']['group']
  end
end
