# frozen_string_literal: true

#
# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

action :configure do
  if node['cluster']['node_type'] == "HeadNode"
    node.force_override['nfs']['threads'] = node['cluster']['nfs']['threads']

    override_server_template

    # Explicitly restart NFS server for thread setting to take effect
    # and enable it to start at boot
    service node['nfs']['service']['server'] do
      action %i(restart enable)
      supports restart: true
      retries 5
      retry_delay 10
    end unless on_docker?
  else
    service node['nfs']['service']['server'] do
      action %i(stop disable)
    end unless on_docker?
  end
end
