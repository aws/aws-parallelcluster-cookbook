# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-config
# Recipe:: update
#
# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# REMINDER: the update recipe runs only on the head node and the only supervisord daemon provided by the
# aws-parallelcluster-node package on the head node is clustermgtd. Therefore, only this daemon is restarted.
execute 'stop clustermgtd' do
  command "#{cookbook_virtualenv_path}/bin/supervisorctl stop clustermgtd"
end

include_recipe 'aws-parallelcluster-computefleet::custom_parallelcluster_node'

execute 'start clustermgtd' do
  command "#{cookbook_virtualenv_path}/bin/supervisorctl start clustermgtd"
end
