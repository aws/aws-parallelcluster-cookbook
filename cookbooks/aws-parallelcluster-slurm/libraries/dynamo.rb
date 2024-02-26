# frozen_string_literal: true

# Copyright:: 2024 Amazon.com, Inc. and its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# Saves on the DynamoDB table 'parallelcluster-$CLUSTERNAME' the correspondence between
# the instance id and the cluster config version deployed on that instance.
# This is done to understand what is the deployed cluster config in each node, for example, during a CFN Stack update.

DDB_CONFIG_STATUS = {
  # The node successfully deployed the cluster configuration.
  DEPLOYED: "DEPLOYED",
}.freeze

def save_instance_config_version_to_dynamodb(status)
  unless on_docker? || kitchen_test? && !node['interact_with_ddb']
    # TODO: the table name should be read from a dedicated node attribute,
    #   but it is currently missing in the dna.json for compute nodes.
    table_name = "parallelcluster-#{node['cluster']['cluster_name']}"
    item_id = "CLUSTER_CONFIG.#{node['ec2']['instance_id']}"
    node_type = node['cluster']['node_type']
    config_version = node['cluster']['cluster_config_version']
    last_update_time = Time.now.utc

    item_data = "{\"cluster_config_version\": {\"S\": \"#{config_version}\"}, \"status\": {\"S\": \"#{status}\"}, \"node_type\": {\"S\": \"#{node_type}\"}, \"lastUpdateTime\": {\"S\": \"#{last_update_time}\"}}"
    item = "{\"Id\": {\"S\": \"#{item_id}\"}, \"Data\": {\"M\": #{item_data}}}"

    execute "Save cluster config version to DynamoDB" do
      command "#{cookbook_virtualenv_path}/bin/aws dynamodb put-item" \
                " --table-name #{table_name}"\
                " --item '#{item}'" \
                " --region #{node['cluster']['region']}"
      retries 3
      retry_delay 5
    end
  end
end
