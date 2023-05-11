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

control 'tag:config_clustermgtd_runs_as_cluster_admin_user' do
  only_if { instance.head_node? && node['cluster']['scheduler'] == 'slurm' && !os_properties.on_docker? }

  describe processes('clustermgtd') do
    its('count') { should eq 1 }
    its('users') { should eq [ node['cluster']['cluster_admin_user'] ] }
  end
end

control 'tag:config_computemgtd_runs_as_cluster_admin_user' do
  only_if { instance.compute_node? && node['cluster']['scheduler'] == 'slurm' }

  describe processes('computemgtd') do
    its('count') { should eq 1 }
    its('users') { should eq [ node['cluster']['cluster_admin_user'] ] }
  end
end
