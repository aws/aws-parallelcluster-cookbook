require 'spec_helper'

describe 'fetch_config:run' do
  context "when running a HeadNode from kitchen" do
    cached(:cluster_shared_dir) { '/cluster_shared_dir' }
    cached(:cluster_config_path) { 'cluster_config_path' }
    cached(:previous_cluster_config_path) { 'previous_cluster_config_path' }
    cached(:cluster_config_version) { 'cluster_config_version' }
    cached(:instance_types_data_path) { 'instance_types_data_path' }
    cached(:previous_instance_types_data_path) { 'previous_instance_types_data_path' }
    cached(:chef_run) do
      runner = ChefSpec::Runner.new(
        platform: 'ubuntu', step_into: %w(fetch_config)
      ) do |node|
        node.override['kitchen'] = true
        node.override['cluster']['shared_dir'] = cluster_shared_dir
        node.override['cluster']['cluster_config_path'] = cluster_config_path
        node.override['cluster']['previous_cluster_config_path'] = previous_cluster_config_path
        node.override['cluster']['cluster_config_version'] = cluster_config_version
        node.override['cluster']['instance_types_data_path'] = instance_types_data_path
        node.override['cluster']['previous_instance_types_data_path'] = previous_instance_types_data_path
        node.override['cluster']['node_type'] = 'HeadNode'
      end
      runner.converge_dsl do
        fetch_config 'run' do
          action :run
        end
      end
    end

    it "copies data from kitchen data dir" do
      is_expected.to create_remote_file("copy fake cluster config")
        .with(path: cluster_config_path)
        .with(source: "file://#{kitchen_cluster_config_path}")

      is_expected.to create_remote_file("copy fake instance type data")
        .with(path: instance_types_data_path)
        .with(source: "file://#{kitchen_instance_types_data_path}")
    end

    it "writes the cluster config version file" do
      is_expected.to create_file("/cluster_shared_dir/cluster-config-version").with(
        content: cluster_config_version,
        mode: '0644',
        owner: 'root',
        group: 'root'
      )
    end

    it "does not wait for cluster config version file" do
      is_expected.not_to run_execute("Wait cluster config files to be updated by the head node")
    end
  end

  %w(ComputeFleet LoginNode).each do |node_type|
    context "when running a #{node_type} from kitchen on create" do
      cached(:cluster_config_path) { 'cluster_config_path' }
      cached(:previous_cluster_config_path) { 'previous_cluster_config_path' }
      cached(:instance_types_data_path) { 'instance_types_data_path' }
      cached(:previous_instance_types_data_path) { 'previous_instance_types_data_path' }
      cached(:chef_run) do
        runner = ChefSpec::Runner.new(
          platform: 'ubuntu', step_into: %w(fetch_config)
        ) do |node|
          node.override['kitchen'] = true
          node.override['cluster']['cluster_config_path'] = cluster_config_path
          node.override['cluster']['login_cluster_config_path'] = cluster_config_path
          node.override['cluster']['node_type'] = node_type
        end
        allow(File).to receive(:exist?).with(cluster_config_path).and_return(true)
        runner.converge_dsl do
          fetch_config 'run' do
            action :run
            update false
          end
        end
      end

      it "does not wait for cluster config version file" do
        is_expected.not_to run_execute("Wait cluster config files to be updated by the head node")
      end

      it "reads config from shared folder" do
        is_expected.to run_ruby_block("load cluster configuration")
      end
    end
  end

  %w(ComputeFleet LoginNode).each do |node_type|
    context "when running a #{node_type} from kitchen on update" do
      cached(:cluster_shared_dir) { '/cluster_shared_dir' }
      cached(:cluster_config_path) { 'cluster_config_path' }
      cached(:previous_cluster_config_path) { 'previous_cluster_config_path' }
      cached(:cluster_config_version) { 'cluster_config_version' }
      cached(:cluster_shared_storages_mapping_path) { '/cluster_shared_storages_mapping_path' }
      cached(:cluster_previous_shared_storages_mapping_path) { '/cluster_previous_shared_storages_mapping_path' }
      cached(:instance_types_data_path) { 'instance_types_data_path' }
      cached(:previous_instance_types_data_path) { 'previous_instance_types_data_path' }
      cached(:chef_run) do
        runner = ChefSpec::Runner.new(
          platform: 'ubuntu', step_into: %w(fetch_config)
        ) do |node|
          node.override['kitchen'] = true
          node.override['cluster']['shared_dir'] = cluster_shared_dir
          node.override['cluster']['cluster_config_path'] = cluster_config_path
          node.override['cluster']['cluster_config_version'] = cluster_config_version
          node.override['cluster']['shared_storages_mapping_path'] = cluster_shared_storages_mapping_path
          node.override['cluster']['previous_shared_storages_mapping_path'] = cluster_previous_shared_storages_mapping_path
          node.override['cluster']['login_cluster_config_path'] = cluster_config_path
          node.override['cluster']['node_type'] = node_type
        end
        allow(File).to receive(:exist?).with(cluster_config_path).and_return(true)
        allow(FileUtils).to receive(:cp_r).with(
          cluster_shared_storages_mapping_path, cluster_previous_shared_storages_mapping_path, remove_destination: true
        ).and_return(true)
        runner.converge_dsl do
          fetch_config 'run' do
            action :run
            update true
          end
        end
      end

      if node_type == "ComputeFleet"
        it "waits for cluster config version file" do
          is_expected.to run_execute("Wait cluster config files to be updated by the head node").with(
            command: "[[ \"$(cat /cluster_shared_dir/cluster-config-version)\" == \"cluster_config_version\" ]]",
            retries: 30,
            retry_delay: 10,
            timeout: 5
          )
        end
      else
        it "does not wait for cluster config version file" do
          is_expected.not_to run_execute("Wait cluster config files to be updated by the head node")
        end
      end

      it "reads config from shared folder" do
        is_expected.to run_ruby_block("load cluster configuration")
      end
    end
  end
end
