# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-slurm
# Recipe:: update_login_node
#
# Copyright:: 2024 Amazon.com, Inc. and its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# TODO: Move the only_if decision to the update_shared_storage recipe for better definition of responsibilities
#  and to facilitate unit testing.
ruby_block "update_shared_storages" do
  block do
    run_context.include_recipe 'aws-parallelcluster-environment::update_shared_storages'
  end
  only_if { are_mount_or_unmount_required? && storage_change_supports_live_update? }
end

save_instance_config_version_to_dynamodb(DDB_CONFIG_STATUS[:DEPLOYED])
