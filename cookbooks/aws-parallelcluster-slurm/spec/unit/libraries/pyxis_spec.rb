require 'spec_helper'

describe "aws-parallelcluster-slurm:libraries:pyxis" do
  let(:node) do
    {
      "cluster" => { "change_set_path" => "/SHARED_DIR/change-set.json" },
    }
  end

  let(:mock_shared_storage_change_info) { instance_double(SharedStorageChangeInfo) }

  shared_examples "the correct method" do |dir_exists, expected_result|
    it "returns #{expected_result}" do
      allow(Dir).to receive(:exist?).with("/usr/local/share/pyxis").and_return(dir_exists)
      result = pyxis_installed?
      expect(result).to eq(expected_result)
    end
  end

  context "when installation folder exists" do
    include_examples "the correct method", true, true
  end

  context "when installation folder does not exist" do
    include_examples "the correct method", false, false
  end
end
