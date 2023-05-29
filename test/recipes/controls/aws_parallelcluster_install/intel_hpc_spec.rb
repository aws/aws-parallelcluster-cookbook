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

control 'tag:install_intel_hpc_dependencies_downloaded' do
  title 'Checks Intel HPC dependencies have been downloaded'

  only_if { os_properties.centos7? }

  node['cluster']['intelhpc']['dependencies'].each do |package|
    # The rpm can be in the sources_dir folder or already installed as dependency of other packages
    describe command("ls #{node['cluster']['sources_dir']}/#{package}*.rpm || rpm -qa #{package}* | grep #{package}") do
      its('exit_status') { should eq 0 }
    end
  end
end
