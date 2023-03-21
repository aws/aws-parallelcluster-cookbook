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

control 'tag:config_dcv_external_authenticator_user_and_group_correctly_defined' do
  only_if { node['conditions']['dcv_supported'] }

  describe user(node['cluster']['dcv']['authenticator']['user']) do
    it { should exist }
    its('uid') { should eq node['cluster']['dcv']['authenticator']['user_id'] }
    its('gid') { should eq node['cluster']['dcv']['authenticator']['group_id'] }
    # 'NICE DCV External Authenticator user'
  end

  describe group(node['cluster']['dcv']['authenticator']['group']) do
    it { should exist }
    its('gid') { should eq node['cluster']['dcv']['authenticator']['group_id'] }
  end
end

control 'tag:config_expected_versions_of_nice-dcv-gl_installed' do
  only_if do
    instance.head_node? && node['conditions']['dcv_supported'] && node['cluster']['dcv_enabled'] == "head_node" &&
      instance.graphic? && instance.nvidia_installed? && instance.dcv_gpu_accel_supported?
  end

  describe package('nice-dcv-gl') do
    it { should be_installed }
    its('version') { should eq node['cluster']['dcv']['gl']['version'] }
  end
end
