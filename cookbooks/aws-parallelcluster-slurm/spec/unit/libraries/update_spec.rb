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
        allow(File).to receive(:read).with(CHANGE_SET_PATH, any_args).and_call_original
      else
        allow(File).to receive(:exist?).with(CHANGE_SET_PATH).and_return(true)
        allow(File).to receive(:read).with(CHANGE_SET_PATH, any_args).and_return(JSON.dump(changeset))
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

  describe "aws-parallelcluster-slurm:libraries:are_queues_updated" do
    CLUSTER_CONFIG_PATH = "/CLUSTER_CONFIG_PATH".freeze
    PREVIOUS_CLUSTER_CONFIG_PATH = "/PREVIOUS_CLUSTER_CONFIG_PATH".freeze

    let(:node) do
      {
        "cluster" => {
          "cluster_config_path" => CLUSTER_CONFIG_PATH,
          "previous_cluster_config_path" => PREVIOUS_CLUSTER_CONFIG_PATH,
        },
      }
    end

    shared_examples "the correct result" do |config, previous_config, file_exists, expected_result|
      it "returns #{expected_result}" do
        allow(File).to receive(:exist?).with(PREVIOUS_CLUSTER_CONFIG_PATH).and_return(file_exists)
        allow(File).to receive(:read).with(CLUSTER_CONFIG_PATH).and_return(YAML.dump(config))
        if file_exists
          allow(File).to receive(:read).with(PREVIOUS_CLUSTER_CONFIG_PATH).and_return(YAML.dump(previous_config))
        end
        result = are_queues_updated?
        expect(result).to eq(expected_result)
      end
    end

    context "when previous cluster config file does not exist" do
      config = {
        "Scheduling" => { "SlurmQueues" => [] },
      }
      previous_config = nil
      include_examples "the correct result", config, previous_config, false, false
    end

    context "when Scheduling sections are identical and bootstrap timeout unchanged" do
      config = {
        "Scheduling" => { "SlurmQueues" => [{ "Name" => "queue1" }] },
      }
      previous_config = {
        "Scheduling" => { "SlurmQueues" => [{ "Name" => "queue1" }] },
      }
      include_examples "the correct result", config, previous_config, true, false
    end

    context "when Scheduling sections are identical and bootstrap timeout is updated" do
      config = {
        "Scheduling" => { "SlurmQueues" => [{ "Name" => "queue1" }] },
        "DevSettings" => { "Timeouts" => { "ComputeNodeBootstrapTimeout" => 3600 } },
      }
      previous_config = {
        "Scheduling" => { "SlurmQueues" => [{ "Name" => "queue1" }] },
        "DevSettings" => { "Timeouts" => { "ComputeNodeBootstrapTimeout" => 1800 } },
      }
      include_examples "the correct result", config, previous_config, true, true
    end

    context "when Scheduling sections are identical and bootstrap timeout changes from default to explicit value" do
      config = {
        "Scheduling" => { "SlurmQueues" => [{ "Name" => "queue1" }] },
        "DevSettings" => { "Timeouts" => { "ComputeNodeBootstrapTimeout" => 3600 } },
      }
      previous_config = {
        "Scheduling" => { "SlurmQueues" => [{ "Name" => "queue1" }] },
      }
      include_examples "the correct result", config, previous_config, true, true
    end

    context "when Scheduling sections are different" do
      config = {
        "Scheduling" => { "SlurmQueues" => [{ "Name" => "queue2" }] },
      }
      previous_config = {
        "Scheduling" => { "SlurmQueues" => [{ "Name" => "queue1" }] },
      }
      include_examples "the correct result", config, previous_config, true, true
    end
  end
end
