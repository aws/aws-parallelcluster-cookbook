require 'spec_helper'

describe "aws-parallelcluster-slurm:libraries:are_mount_or_unmount_required" do
  CHANGE_SET_PATH = "/CHANGE_SET_PATH".freeze

  let(:node) do
    {
      "cluster" => { "change_set_path" => CHANGE_SET_PATH },
    }
  end

  shared_examples "the correct method" do |changeset, expected_result|
    it "returns #{expected_result}" do
      if changeset.nil?
        allow(File).to receive(:exist?).with(CHANGE_SET_PATH).and_return(false)
        allow(File).to receive(:read).with(CHANGE_SET_PATH).and_call_original
      else
        allow(File).to receive(:exist?).with(CHANGE_SET_PATH).and_return(true)
        allow(File).to receive(:read).with(CHANGE_SET_PATH).and_return(JSON.dump(changeset))
      end
      result = are_mount_or_unmount_required?
      expect(result).to eq(expected_result)
    end
  end

  context "when changeset does not exist" do
    changeset = nil
    include_examples "the correct method", changeset, false
  end

  context "when changeset is empty" do
    changeset = {
      "changeSet" => [],
    }
    include_examples "the correct method", changeset, false
  end

  context "when changeset does not contain any change with SHARED_STORAGE_UPDATE_POLICY" do
    changeset = {
      "changeSet" => [
        {
          updatePolicy: "NOT_SHARED_STORAGE_UPDATE_POLICY",
        },
      ],
    }
    include_examples "the correct method", changeset, false
  end

  context "when changeset contains at least a change with SHARED_STORAGE_UPDATE_POLICY" do
    changeset = {
      "changeSet" => [
        {
          updatePolicy: "SHARED_STORAGE_UPDATE_POLICY",
        },
        {
          updatePolicy: "NOT_SHARED_STORAGE_UPDATE_POLICY",
        },
      ],
    }
    include_examples "the correct method", changeset, true
  end
end
