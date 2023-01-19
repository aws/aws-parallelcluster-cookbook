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

python_version = '3.9.16'
base_dir = "/opt/parallelcluster"
pyenv_dir = "#{base_dir}/pyenv"

control 'awscli_is_installed' do
  title 'awscli package should be installed in cookbook virtualenv'

  only_if { !os_properties.redhat_ubi? }

  describe bash("#{pyenv_dir}/versions/#{python_version}/envs/cookbook_virtualenv/bin/pip list") do
    its('exit_status') { should eq(0) }
    its('stdout')      { should match('awscli') }
  end

  describe file('/usr/local/bin/aws') do
    it { should exist }
  end
end
