# frozen_string_literal: true

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

provides :node_attributes
unified_mode true
default_action :generate_json

action :generate_json do
  json_content = Chef::JSONCompat.to_json_pretty(node)
  file "/etc/chef/node_attributes.json" do
    content "#{json_content}"
    owner 'root'
    mode '0644'
  end
end
