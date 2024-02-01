# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-slurm
# Recipe:: config_external_slurmdbd_s3_mountpoint
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

ext = platform?('ubuntu') ? "deb" : "rpm"
subtree = arm? ? "arm64" : "x86_64"
mount_s3_url = "https://s3.amazonaws.com/mountpoint-s3-release/latest/#{subtree}/mount-s3.#{ext}"
download_path = "/tmp/mount-s3.#{ext}"

remote_file 'download mountpoint-s3' do
  source mount_s3_url
  path download_path
  retries 3
  retry_delay 5
  action :create_if_missing
end

if platform?('ubuntu')
  # The Chef apt_package resource does not support the source attribute, so we use the dpkg_package resource instead.
  dpkg_package "Install mountpoint-s3" do
    source download_path
  end
else
  package "Install mountpoint-s3" do
    source download_path
  end
end

execute 'mount slurmdbd configuration via S3' do
  command "mount-s3 --allow-delete --uid $(id -u slurm) --gid $(id -g slurm) --dir-mode 0755 --file-mode 0600 #{node['slurmdbd_conf_bucket']} /opt/slurm/etc/"
  user 'root'
end
