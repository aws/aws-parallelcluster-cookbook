# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

control 'tag:config_cluster_user' do
  title 'Check the cluster user configuration'

  only_if { instance.head_node? }
  # Check if authorized_keys_cluster has been created
  # The command checks all the homes with globbing since the user can be different for each OS
  describe command("sudo su -c 'ls /home/*/.ssh/authorized_keys_cluster'") do
    its('exit_status') { should eq 0 }
  end unless os_properties.redhat_on_docker?
end

control 'cluster_user_compute' do
  title 'Check the cluster user configuration for compute node'

  only_if { !os_properties.on_docker? && instance.compute_node? }

  describe 'Check that cluster user exist'
  describe user('test_user') do
    it { should exist }
    its('home') { should eq '/home/test_user' }
    its('shell') { should eq '/bin/bash' }
  end
end
