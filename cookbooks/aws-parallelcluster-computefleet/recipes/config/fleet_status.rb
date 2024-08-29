# frozen_string_literal: true

#
# Copyright:: 2013-2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

return if node['cluster']['scheduler'] == 'awsbatch'

case node['cluster']['node_type']
when 'HeadNode'
  cookbook_file "#{node['cluster']['scripts_dir']}/compute_fleet_status.py" do
    source 'compute_fleet_status/compute_fleet_status.py'
    owner 'root'
    group 'root'
    mode '0755'
    action :create_if_missing
  end

  template "/usr/local/bin/update-compute-fleet-status.sh" do
    source 'compute_fleet_status/update-compute-fleet-status.erb'
    owner 'root'
    group 'root'
    mode '0755'
  end

  template "/usr/local/bin/get-compute-fleet-status.sh" do
    source 'compute_fleet_status/get-compute-fleet-status.erb'
    owner 'root'
    group 'root'
    mode '0755'
  end

  template "/usr/local/bin/is_fleet_ready.sh" do
    source 'compute_fleet_status/is_fleet_ready.erb'
    owner 'root'
    group 'root'
    mode '0755'
  end

  template "#{node['cluster']['etc_dir']}/clusterstatusmgtd.conf" do
    source 'clusterstatusmgtd/clusterstatusmgtd.conf.erb'
    owner 'root'
    group 'root'
    mode '0644'
  end

  unless on_docker? || kitchen_test? && !node['interact_with_ddb']
    execute 'initialize compute fleet status in DynamoDB' do
      # Initialize the status of the compute fleet in the DynamoDB table. Set it to RUNNING.
      command "#{cookbook_virtualenv_path}/bin/aws dynamodb put-item --table-name #{node['cluster']['ddb_table']}"\
              " --item '{\"Id\": {\"S\": \"COMPUTE_FLEET\"}, \"Data\": {\"M\": {\"status\": {\"S\": \"RUNNING\"}, \"lastStatusUpdatedTime\": {\"S\": \"#{Time.now.utc}\"}}}}'" \
              " --region #{node['cluster']['region']}"
      retries 3
      retry_delay 5
    end
  end
end
