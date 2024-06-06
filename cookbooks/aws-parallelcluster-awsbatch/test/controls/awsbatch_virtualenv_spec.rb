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

python_version = '3.9.19'
base_dir = "/opt/parallelcluster"
pyenv_dir = "#{base_dir}/pyenv"

control 'tag:install_awsbatch_virtualenv_created' do
  title "awsbatch virtualenv should be created on #{python_version}"
  only_if { !os_properties.redhat? }

  describe directory("#{pyenv_dir}/versions/#{python_version}/envs/awsbatch_virtualenv") do
    it { should exist }
    its('mode') { should cmp '0755' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
  end
end
