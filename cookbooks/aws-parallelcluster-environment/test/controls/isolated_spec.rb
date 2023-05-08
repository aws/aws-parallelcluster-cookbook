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

control 'tag:install_patch_isolated_instance_script_created' do
  title 'Verify sudoers file is correctly configured'

  describe file('/opt/parallelcluster/scripts/patch-iso-instance.sh') do
    it { should exist }
    its('owner') { should cmp 'root' }
    its('group') { should cmp 'root' }
    its('mode') { should cmp '0744' }
    its('content') { should match /USERS=\(root #{node['cluster']['cluster_admin_user']} #{node['cluster']['cluster_user']}\)/ }
  end
end
