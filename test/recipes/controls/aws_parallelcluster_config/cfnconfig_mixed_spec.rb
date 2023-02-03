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

control 'cfnconfig_file_configuration' do
  title 'Check the creation of cfnconfig file'

  describe file('/etc/parallelcluster/cfnconfig') do
    it { should exist }
    its('content') { should match /^cfn_region=\w+/ }
    its('content') { should match /^cfn_scheduler_slots=\w+/ }
  end

  describe file('/opt/parallelcluster/cfnconfig') do
    it { should exist }
    its('link_path') { should eq '/etc/parallelcluster/cfnconfig' }
  end
end
