# frozen_string_literal: true

# Copyright:: 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance
# with the License. A copy of the License is located at http://aws.amazon.com/apache2.0/
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

resource_name :fetch_artifacts
provides :fetch_artifacts
unified_mode true

# Resource to fetch cluster shared artifacts

property :plugin_resources, Hash, required: false
property :force_download, [true, false],
         default: false,
         description: 'force download if file exists'

default_action :run

action :run do
  Chef::Log.debug("Called fetch_artifacts with plugin_resources (#{new_resource.plugin_resources})")

  if new_resource.plugin_resources && !new_resource.plugin_resources.empty?
    shared_artifacts = new_resource.plugin_resources[:ClusterSharedArtifacts]
    if shared_artifacts && !shared_artifacts.empty?
      shared_artifacts.each do |artifact|
        artifact_source_url = artifact[:Source]
        s3_bucket_owner = artifact[:S3BucketOwner]
        source_name = artifact_source_url.split("/")[-1]
        target_source_path = "#{node['cluster']['scheduler_plugin']['home']}/#{source_name}"
        next if ::File.exist?(target_source_path) && !new_resource.force_download

        Chef::Log.info("Downloading artifacts from (#{artifact_source_url}) to (#{target_source_path})")
        if artifact_source_url.start_with?("s3")
          # download artifacts from s3
          bucket_name, object_key = artifact_source_url.match(%r{^s3:\/\/(.*?)\/(.*)}).captures
          fetch_artifact_command = "#{cookbook_virtualenv_path}/bin/aws s3api get-object" \
                         " --bucket #{bucket_name}" \
                         " --key #{object_key}" \
                         " --region #{node['cluster']['region']}" \
                         " #{target_source_path}"
          fetch_artifact_command += " --expected-bucket-owner #{s3_bucket_owner}" unless s3_bucket_owner.nil?

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

        # Verify checksum of artifact
        ruby_block "verify artifact checksum" do
          block do
            if artifact[:Checksum]
              require 'digest'
              checksum = Digest::SHA256.file(target_source_path).hexdigest
              raise "The checksum of artifact #{artifact_source_url} (#{checksum}) does not match expected checksum (#{artifact[:Checksum]})" unless checksum == artifact[:Checksum]
            end
          end
        end

        Chef::Log.info("Changing ownership of file (#{target_source_path}) to (#{node['cluster']['scheduler_plugin']['user']})")
        file target_source_path do
          mode '0744'
          owner node['cluster']['scheduler_plugin']['user']
          group node['cluster']['scheduler_plugin']['group']
        end
      end
    end
  else
    Chef::Log.info("No shared artifacts to download")
  end
end
