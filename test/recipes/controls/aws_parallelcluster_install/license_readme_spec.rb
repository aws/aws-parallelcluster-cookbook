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

control 'license_readme_created' do
  title 'Check that the license readme file has been created'

  describe file("/opt/parallelcluster/licenses/AWS-ParallelCluster-License-README.txt") do
    it { should exist }
    its('mode') { should cmp '0644' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('content') do
      should eq %(AWS ParallelCluster is licensed under the Apache License 2.0 (http://aws.amazon.com/apache2.0/).

AWS ParallelCluster AMIs ship with the following independent packages, which are offered
under separate terms.

sge
slurm
torque

For each package, the license is available in the /opt/parallelcluster/licenses/<package>
directory, and the source code is available in the /opt/parallelcluster/sources directory.
)
    end
  end
end
