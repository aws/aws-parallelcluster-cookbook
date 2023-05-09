# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: unmount_home
#
# Copyright:: 2013-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.
#
# Needed to unmount the home directory in compute nodes to avoid Kitchen test to fail in the verify step.
# Without this, the verify step cannot connect to the instance as it cannot find the key

execute 'unmount /home' do
  command "umount -fl /home"
  retries 10
  retry_delay 6
  timeout 60
  only_if { node['cluster']['node_type'] == 'ComputeFleet' }
end
