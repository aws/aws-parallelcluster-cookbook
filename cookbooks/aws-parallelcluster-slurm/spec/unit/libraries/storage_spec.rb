require 'spec_helper'

describe "aws-parallelcluster-slurm:libraries:storage_change_supports_live_update" do
  let(:node) do
    {
      "cluster" => { "change_set_path" => "/SHARED_DIR/change-set.json" },
    }
  end

  let(:mock_shared_storage_change_info) { instance_double(SharedStorageChangeInfo) }

  shared_examples "the correct method" do |changeset, info_outcome, expected_result|
    it "returns #{expected_result}" do
      allow(File).to receive(:read).with("/SHARED_DIR/change-set.json").and_return(JSON.dump(changeset))
      allow(SharedStorageChangeInfo).to receive(:new).and_return(mock_shared_storage_change_info)
      allow(mock_shared_storage_change_info).to receive(:support_live_updates?).and_return(info_outcome)
      result = storage_change_supports_live_update?
      expect(result).to eq(expected_result)
    end
  end

  context "when changeset is empty" do
    changeset = {
      "changeSet" => [],
    }
    include_examples "the correct method", changeset, nil, true
  end

  context "when changeset does not contain any change for SharedStorage" do
    changeset = {
      "changeSet" => [
        {
          parameter: "NOT_SharedStorage",
        },
      ],
    }
    include_examples "the correct method", changeset, nil, true
  end

  context "when changeset contains a change for SharedStorage" do
    changeset = {
      "changeSet" => [
        {
          parameter: "SharedStorage",
        },
        {
          parameter: "NOT_SharedStorage",
        },
      ],
    }
    [true, false].each do |info_outcome|
      context "and SharedStorageChangeInfo says it is #{'not ' unless info_outcome}supported" do
        expected_result = info_outcome
        include_examples "the correct method", changeset, info_outcome, expected_result
      end
    end
  end
end

def build_storage_change(type, ownership, action)
  storage_identified = case type
                       when "Ebs", "FsxOntap", "FsxOpenZfs"
                         "VolumeId"
                       when "FileCache"
                         "FileCacheId"
                       else
                         "FileSystemId"
                       end
  storage_settings = case ownership
                     when "external"
                       {
                         storage_identified => "STORAGE_ID",
                       }
                     when "managed"
                       {
                         "SETTING_1" => "VALUE_1",
                         "SETTING_2" => "VALUE_2",
                       }
                     end
  case action
  when "mount"
    current_value = nil
    requested_value = {
      "MountDir" => "/opt/shared/#{type}/#{ownership}/1",
      "Name" => "shared-#{type}-#{ownership}-external-1",
      "StorageType" => "#{type}",
      "#{type}Settings" => storage_settings,
    }
  when "unmount"
    current_value = {
      "MountDir" => "/opt/shared/#{type}/#{ownership}/1",
      "Name" => "shared-#{type}-#{ownership}-external-1",
      "StorageType" => "#{type}",
      "#{type}Settings" => storage_settings,
    }
    requested_value = nil
  else
    raise "Unrecognized action #{action}. It must be one of : mount, unmount"
  end

  {
    "parameter" => "SharedStorage",
    "currentValue" => current_value,
    "requestedValue" => requested_value,
  }
end

describe "aws-parallelcluster-slurm:libraries:SharedStorageChangeInfo" do
  shared_examples "behaves correctly" do |change, expected_result|
    it "support_live_updates? returns the correct value" do
      result = SharedStorageChangeInfo.new(change).support_live_updates?
      expect(result).to eq(expected_result)
    end
  end

  %w(Ebs Efs FsxLustre FsxOntap FsxOpenZfs FileCache).each do |storage_type|
    %w(external managed).each do |storage_ownership|
      %w(mount unmount).each do |storage_action|
        context "when #{storage_action}ing #{storage_ownership} #{storage_type}" do
          change = build_storage_change(storage_type, storage_ownership, storage_action)
          expected_result = %(Efs FsxLustre FsxOntap FsxOpenZfs FileCache).include?(storage_type) && storage_ownership == "external"
          include_examples "behaves correctly", change, expected_result
        end
      end
    end
  end
end
