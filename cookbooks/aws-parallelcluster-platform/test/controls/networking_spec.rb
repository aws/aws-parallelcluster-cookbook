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

control 'tag:config_networking' do
  title 'Check that networking has been configured'

  only_if { !os_properties.on_docker? }

  describe kernel_parameter('net.core.somaxconn') do
    its('value') { should eq 65_535 }
  end

  describe kernel_parameter('net.ipv4.tcp_max_syn_backlog') do
    its('value') { should eq 65_535 }
  end
end
