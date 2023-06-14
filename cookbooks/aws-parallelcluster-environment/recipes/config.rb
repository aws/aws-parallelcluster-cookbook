# frozen_string_literal: true

# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

efa 'Configure system for EFA' do
  action :configure
end
nfs "Configure NFS" do
  action :configure
end
include_recipe 'aws-parallelcluster-environment::ephemeral_drives'
# fs_update generates the shared storages mapping file so must be executed before shared storages recipes
include_recipe 'aws-parallelcluster-environment::fs_update'
include_recipe 'aws-parallelcluster-environment::shared_storages'
include_recipe 'aws-parallelcluster-environment::ebs'
include_recipe 'aws-parallelcluster-environment::raid'
include_recipe "aws-parallelcluster-environment::fs_mount"
