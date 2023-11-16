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

control 'custom_parallelcluster_node_installed' do
  title "custom aws-parallelcluster-node should have been installed in the node virtualenv"
  only_if { !os_properties.redhat_on_docker? }

  describe command("#{node['cluster']['node_virtualenv_path']}/bin/pip freeze | grep aws-parallelcluster-node") do
    its('exit_status') { should eq(0) }
    its('stdout') { should match "aws-parallelcluster-node" }
  end
end
