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

plugin_resources(lazy { node['cluster']['config'].dig(:Scheduling, :ByosSettings, :SchedulerDefinition, :PluginResources) })
if plugin_resources && !plugin_resources.empty?
  shared_artifacts = plugin_resources[:ClusterSharedArtifacts]
  if shared_artifacts && !shared_artifacts.empty?
    shared_artifacts.each do |artifact|
      artifact_source_url = artifact[:Source]
      source_name = artifact_source_url.split("/")[-1]
      target_source_path = "#{node['cluster']['byos']['shared_dir']}/#{source_name}"
      next if ::File.exist?(target_source_path)

      Chef::Log.info("Downloading artifacts from (#{artifact_source_url}) to (#{target_source_path})")
      if artifact_source_url.start_with?("s3")
        # download artifacts from s3
        fetch_artifact_command = "#{node['cluster']['cookbook_virtualenv_path']}/bin/aws s3 cp"\
                           " --region #{node['cluster']['region']}"\
                           " #{artifact_source_url}"\
                           " #{target_source_path}"
        execute "copy_shared_artifact_from_s3" do
          command fetch_artifact_command
          retries 3
          retry_delay 5
        end
      else
        # download artifacts from https
        remote_file target_source_path do
          source artifact_source_url
          retries 3
          retry_delay 5
        end
      end

      Chef::Log.info("Changing ownership of file (#{target_source_path}) to (#{node['cluster']['byos']['user']})")
      file target_source_path do
        mode '0744'
        owner node['cluster']['byos']['user']
        group node['cluster']['byos']['group']
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
