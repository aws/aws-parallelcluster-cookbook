# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: finalize_directory_service
#
# Copyright:: 2024 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

return if node['cluster']["directory_service"]["enabled"] == 'false'

if %w(HeadNode LoginNode).include? node['cluster']['node_type']
  default_user = node['cluster']['cluster_user']
  read_only_user = domain_service_read_only_user_name(node['cluster']['directory_service']['domain_read_only_user'])

  execute 'Fetch user data from remote directory service' do
    # The switch-user (sudo -u) is necessary to trigger the fetching of AD data
    command "sudo -u #{default_user} getent passwd #{read_only_user}"
    user 'root'
    retries 10 # Retries are just a safe guard in case the node is still fetching data from the AD
    retry_delay 3
  end
end
