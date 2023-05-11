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

control 'gc_thresh_values_configured' do
  title 'Verify gc_thresh values are configured in the kernel settings'

  only_if { !os_properties.virtualized? }

  # We cannot access node attributes in the inspec tests
  @thresh_numbers = [ 1, 2, 3 ]
  @thresh_values = [ 0, 15_360, 16_384 ]

  @thresh_numbers.zip(@thresh_values).each do |thresh_number, thresh_value|
    describe kernel_parameter("net.ipv4.neigh.default.gc_thresh#{thresh_number}") do
      its('value') { should eq thresh_value }
    end
  end
end

control 'tag:config_ipv4_gc_thresh_correctly_configured' do
  only_if { !os_properties.on_docker? }

  (1..3).each do |i|
    describe bash("cat /proc/sys/net/ipv4/neigh/default/gc_thresh#{i}") do
      its('stdout.strip') { should cmp node['cluster']['sysctl']['ipv4']["gc_thresh#{i}"] }
    end
  end
end
