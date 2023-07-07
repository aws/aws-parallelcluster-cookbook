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

control 'mount_slurm_dir' do
  title 'Check if the slurm install dir is mounted'

  only_if { !os_properties.on_docker? && (instance.compute_node? or instance.login_node?) }

  describe mount('/opt/slurm') do
    it { should be_mounted }
    its('type') { should eq 'nfs4' }
    its('options') { should include 'rw' }
  end
end
