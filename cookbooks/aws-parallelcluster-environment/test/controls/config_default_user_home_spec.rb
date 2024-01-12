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

control 'local_default_user_home' do
  title 'Check if the home directory is in a local directory'

  only_if { !os_properties.on_docker? }

  describe directory("/local/home") do
    it { should exist }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0755' }
  end
  describe directory("#{node['cluster']['cluster_user_local_home']}") do
    it { should exist }
    its('owner') { should eq "#{node['cluster']['cluster_user']}" }
    its('group') { should eq "#{node['cluster']['cluster_user']}" }
    its('mode') { should cmp '0700' }
  end
end
