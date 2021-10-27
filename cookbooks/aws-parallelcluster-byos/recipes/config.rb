# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster-byos
# Recipe:: config
#
# Copyright 2013-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

plugin_resources = Enumerator::lazy { node['cluster']['config'].dig(:Scheduling, :ByosSettings, :SchedulerDefinition, :PluginResources) }
unless plugin_resources.nil? || plugin_resources.empty?
  shared_artifacts = plugin_resources[:ClusterSharedArtifacts]
  unless shared_artifacts.nil? || shared_artifacts.empty?
    shared_artifacts.each do |artifact|
      artifact_source_url = artifact[:Source]
      source_name = artifact_source_url.split("/")[-1]
      target_source_path = "#{node['cluster']['byos']['shared_dir']}/#{source_name}"

      if artifact_source_url.start_with?("s3")
        # get shared artifacts from s3
        fetch_artifact_command = "#{node['cluster']['cookbook_virtualenv_path']}/bin/aws s3 cp"\
                             " #{artifact_source_url}"\
                             " #{target_source_path}"\
                             " --region #{node['cluster']['region']}"
        execute "copy_shared_artifact_from_s3" do
          command fetch_artifact_command
          retries 3
          retry_delay 5
          not_if { ::File.exist?(target_source_path) }
        end
      else
        # download shared artifacts from https
        remote_file target_source_path do
          source artifact_source_url
          mode '0644'
          retries 3
          retry_delay 5
          not_if { ::File.exist?(target_source_path) }
        end
      end
    end
  end
end


case node['cluster']['node_type']
when 'HeadNode'
  include_recipe 'aws-parallelcluster-byos::config_head_node'
when 'ComputeFleet'
  include_recipe 'aws-parallelcluster-byos::config_compute'
else
  raise "node_type must be HeadNode or ComputeFleet"
end
