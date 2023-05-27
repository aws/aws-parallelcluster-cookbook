# frozen_string_literal: true

# Copyright:: 2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

# Parse an ARN.
# ARN format: arn:PARTITION:SERVICE:REGION:ACCOUNT_ID:RESOURCE.
# ARN examples:
#   1. arn:aws:secretsmanager:eu-west-1:12345678910:secret:PasswordName
#   2. arn:aws:ssm:eu-west-1:12345678910:parameter/PasswordName
def parse_arn(arn_string)
  parts = arn_string.nil? ? [] : arn_string.split(':', 6)
  raise TypeError if parts.size < 6

  {
    partition: parts[1],
    service: parts[2],
    region: parts[3],
    account_id: parts[4],
    resource: parts[5],
  }
end

# load shared storages data into node object
def load_shared_storages_mapping
  ruby_block "load shared storages mapping during cluster update" do
    block do
      require 'yaml'
      # regenerate the shared storages mapping file after update
      node.default['cluster']['shared_storages_mapping'] = YAML.safe_load(File.read(node['cluster']['previous_shared_storages_mapping_path']))
      node.default['cluster']['update_shared_storages_mapping'] = YAML.safe_load(File.read(node['cluster']['shared_storages_mapping_path']))
    end
  end
end
