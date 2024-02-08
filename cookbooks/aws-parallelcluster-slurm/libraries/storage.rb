# frozen_string_literal: true

# Copyright:: 2024 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.
# rubocop:disable Style/SingleArgumentDig

STORAGE_TYPES_SUPPORTING_LIVE_UPDATES = %w(Efs FsxLustre FsxOntap FsxOpenZfs FileCache).freeze
EXTERNAL_STORAGE_KEYS = %w(VolumeId FileSystemId FileCacheId).freeze

class SharedStorageChangeInfo
  attr_reader :is_mount, :is_unmount, :storage_type, :storage_settings, :is_external

  # Creates a new instance of SharedStorageChangeInfo capturing the relevant information out of the given
  # shared storage change of a change-set.
  #
  # @param [any] change a change provided by a change-set. Example of a change:
  #                     {
  #                       "parameter": "SharedStorage",
  #                       "requestedValue": {
  #                         "MountDir": "/opt/shared/efs/managed/1",
  #                         "Name": "shared-efs-managed-1",
  #                         "StorageType": "Efs",
  #                         "EfsSettings": {
  #                           "FileSystemId": "fs-123456789"
  #                         },
  #                       "currentValue": "-"
  #                      }
  def initialize(change)
    old_value = change["currentValue"]
    new_value = change["requestedValue"]

    storage_item = new_value.nil? ? old_value : new_value

    # Storage Action
    @is_mount = (old_value.nil? and !new_value.nil?)
    @is_unmount = (!old_value.nil? and new_value.nil?)

    @storage_type = storage_item["StorageType"]
    @storage_settings = storage_item["#{@storage_type}Settings"] || {}

    # Storage Ownership
    @is_external = @storage_settings.keys.any? { |k| EXTERNAL_STORAGE_KEYS.include?(k) }
  end

  # Checks if a given shared storage change within a changeset supports live updates.
  # With live updates we refer to in-place updates that do not required node replacement.
  # Currently, a live update is supported only in the following cases:
  #   1. mount/unmount of external EFS
  #   1. mount/unmount of external FSx
  #
  # @return [Boolean] true if the change supports live updates; false, otherwise.
  def support_live_updates?
    @is_external and STORAGE_TYPES_SUPPORTING_LIVE_UPDATES.include?(@storage_type)
  end

  # Returns the string representation of the object.
  #
  # @return [String] the string representation of the object.
  def to_s
    attributes = instance_variables.reduce [] do |list, attribute|
      list.append "#{attribute}=#{instance_variable_get(attribute).inspect}"
    end

    "{#{attributes.join(', ')}}"
  end
end

# Checks if the given changes provided by a change-set support live updates.
# With live updates we refer to in-place updates that do not required node replacement.
# The decision on the support is demanded to SharedStorageChangeInfo.
# If the changes are nil, empty or they do not contain any shared storage change,
# we assume that a live update is supported.
# Example of a change:
#   {
#     "parameter": "SharedStorage",
#     "requestedValue": {
#       "MountDir": "/opt/shared/efs/managed/1",
#       "Name": "shared-efs-managed-1",
#       "StorageType": "Efs",
#       "EfsSettings": {
#         "FileSystemId": "fs-123456789"
#       },
#     "currentValue": "-"
#    }
#
# @param [List[change]] changes the list fo changes provided by a change-set.
# @return [Boolean] true if the change supports live updates; false, otherwise.
def storage_change_supports_live_update?(changes)
  if changes.nil? || changes.empty?
    Chef::Log.info("No change found: assuming live update is supported")
    return true
  end

  storage_changes = changes.select { |change| change["parameter"] == "SharedStorage" }

  if storage_changes.empty?
    Chef::Log.info("No shared storage change found: assuming live update is supported")
    return true
  end

  storage_changes.each do |change|
    Chef::Log.info("Analyzing shared storage change: #{change}")
    change_info = SharedStorageChangeInfo.new(change)
    Chef::Log.info("Generated shared storage change info: #{change_info}")
    supported = change_info.support_live_updates?
    Chef::Log.info("Change #{change} #{'does not ' unless supported}support live updates")
    return false unless supported
  end
  Chef::Log.info("All shared storage changes support live update.")
  true
end
