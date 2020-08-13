# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: _master_slurm_finalize
#
# Copyright 2013-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

execute 'initialize compute fleet status' do
  # Initialize the status of the compute fleet in the DynamoDB table. Set it to RUNNING.
  command "#{node['cfncluster']['cookbook_virtualenv_path']}/bin/aws dynamodb put-item --table-name #{node['cfncluster']['cfn_ddb_table']}"\
          " --item '{\"Id\": {\"S\": \"COMPUTE_FLEET\"}, \"Status\": {\"S\": \"RUNNING\"}}' --region #{node['cfncluster']['cfn_region']}"
  retries 3
  retry_delay 5
end
