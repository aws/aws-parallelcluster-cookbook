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

control 'tag:install_pyxis_installed' do
  only_if { ['yes', true].include?(node['cluster']['nvidia']['enabled']) }

  title 'Checks Pyxis has been installed'

  describe directory('/opt/slurm/etc') do
    it { should exist }
    its('mode') { should cmp '0755' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
  end

  examples_dir = "/opt/parallelcluster/configs/examples"
  dirs = [ examples_dir, "#{examples_dir}/spank", "#{examples_dir}/pyxis" ]
  dirs.each do |path|
    describe directory(path) do
      it { should exist }
    end
  end

  describe file("#{examples_dir}/pyxis/pyxis.conf") do
    it { should exist }
  end

  describe file("#{examples_dir}/spank/plugstack.conf") do
    it { should exist }
  end
end
