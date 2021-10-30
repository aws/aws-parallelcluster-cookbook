# frozen_string_literal: true

resource_name :fetch_artifacts
provides :fetch_artifacts

# Resource to fetch cluster shared artifacts

property :name, String, name_property: true
property :plugin_resources, Hash, required: false

default_action :run

action :run do
  Chef::Log.debug("Called fetch_artifacts with plugin_resources (#{new_resource.plugin_resources})")

  if new_resource.plugin_resources && !new_resource.plugin_resources.empty?
    shared_artifacts = new_resource.plugin_resources[:ClusterSharedArtifacts]
    if shared_artifacts && !shared_artifacts.empty?
      shared_artifacts.each do |artifact|
        artifact_source_url = artifact[:Source]
        source_name = artifact_source_url.split("/")[-1]
        target_source_path = "#{node['cluster']['byos']['home']}/#{source_name}"
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
          remote_file "copy_shared_artifact_from_https" do
            path target_source_path
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
  else
    Chef::Log.info("No shared artifacts to download")
  end
end
