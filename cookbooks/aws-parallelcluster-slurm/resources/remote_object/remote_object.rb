# frozen_string_literal: true

# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance
# with the License. A copy of the License is located at http://aws.amazon.com/apache2.0/
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

resource_name :remote_object
provides :remote_object
unified_mode true

# Resource to retrieve a remote object either using the S3 or HTTPS protocol
property :url, required: true,
         description: 'Source URI of the remote file'
property :destination, required: true,
         description: 'Local destination path where to store the file'
property :sensitive, [true, false],
         default: false,
         description: 'mark the resource as senstive'

default_action :get

action :get do
  if !new_resource.url.blank? && !new_resource.destination.blank?
    source_url = new_resource.url
    local_path = new_resource.destination
    # if running a test skip credential check
    no_sign_request = kitchen_test? ? "--no-sign-request" : ""

    if source_url.start_with?("s3")
      Chef::Log.debug("Retrieving remote Object from #{source_url} to #{local_path} using S3 protocol")
      # download file using s3 protocol
      fetch_command = "#{node['cluster']['cookbook_virtualenv_path']}/bin/aws s3 cp" \
                  " --region #{node['cluster']['region']}" \
                  " #{no_sign_request}" \
                  " #{source_url}" \
                  " #{local_path}"

      Chef::Log.warn("executing command #{fetch_command} ")
      execute "retrieve_object_with_s3_protocol" do
        command fetch_command
        retries 3
        retry_delay 5
      end
    else
      Chef::Log.debug("Retrieving remote Object from #{source_url} to #{local_path}")

      # download file using standard chef behavior
      remote_file "retrieve_object" do
        path local_path
        source source_url
        sensitive new_resource.sensitive
        retries 3
        retry_delay 5
      end
    end
  else
    Chef::Log.warn("Either source or destination is not defined: #{new_resource.url} to #{new_resource.destination}")
  end
end
