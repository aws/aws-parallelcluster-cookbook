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

  describe file("/opt/slurm/etc/plugstack.conf.d/pyxis.conf") do
    it { should exist }
  end

  describe file("/usr/local/share/pyxis/pyxis.conf") do
    it { should be_symlink }
    it { should be_linked_to "/opt/slurm/etc/plugstack.conf.d/pyxis.conf" }
  end
end
