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

control 'tag:install_stunnel_installed' do
  title "Check that the correct version of stunnel has been installed"

  # In AL2 stunnel comes as part of the aws-efs-utils package.
  # In RHEL8 and Rocky8 on Docker we disable the installation of base packages, so stunnel cannot be built.
  only_if { !os_properties.alinux2? && !os_properties.redhat_on_docker? && !os_properties.rocky_on_docker? }

  stunnel_version = node['cluster']['stunnel']['version']

  describe bash("/bin/stunnel -version 2>&1 | awk '/^stunnel / { printf $2 }'") do
    its('exit_status') { should eq 0 }
    its('stdout') { should eq stunnel_version }
  end
end
