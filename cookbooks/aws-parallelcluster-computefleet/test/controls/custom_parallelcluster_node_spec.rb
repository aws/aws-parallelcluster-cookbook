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
  file_cache_path = "/tmp/kitchen/cache"

  title "custom aws-parallelcluster-node should have been installed in the node virtualenv"
  only_if { !os_properties.redhat_ubi? }

  # Unless we fix the version of aws-parallelcluster-node to be installed, we cannot really say from pip if a custom
  # node package was installed. The only thing we can test is that the custom node recipe was triggered, which can
  # be verified from some artifacts left in the kitchen cache folder.
  describe file("#{file_cache_path}/aws-parallelcluster-node.tgz") do
    it { should exist }
  end
  describe directory("#{file_cache_path}/aws-parallelcluster-custom-node") do
    it { should exist }
  end
end
