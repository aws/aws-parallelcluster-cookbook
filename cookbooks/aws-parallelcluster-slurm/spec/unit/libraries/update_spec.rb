require 'spec_helper'

describe "aws-parallelcluster-slurm:libraries:are_mount_unmount_required" do
  let(:node) do
    {
      "cluster" => { "shared_dir" => "/SHARED_DIR" },
    }
  end

  shared_examples "the correct method" do |changeset, expected_result|
    it "returns #{expected_result}" do
      allow(File).to receive(:read).with("/SHARED_DIR/change-set.json").and_return(JSON.dump(changeset))
      result = are_mount_or_unmount_required?
      expect(result).to eq(expected_result)
    end
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
