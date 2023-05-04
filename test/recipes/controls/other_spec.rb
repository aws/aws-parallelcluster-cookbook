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

control 'tag:config_enough_space_on_root_volume' do
  only_if { !instance.custom_ami? }

  describe 'at least 10 GB of free space on root volume' do
    subject { bash("sudo -u #{node['cluster']['cluster_user']} df --block-size GB --output=avail / | tail -n1 | cut -d G -f1") }
    its('stdout') { should cmp >= '10' }
  end
end

control 'tag:config_no_mpich_packages' do
  describe bash('ls 2>/dev/null /usr/lib64/mpich*') do
    its('stdout') { should be_empty }
  end

  describe bash('ls 2>/dev/null /usr/lib/mpich*') do
    its('stdout') { should be_empty }
  end
end

control 'tag:config_no_fftw_packages' do
  only_if { !os_properties.centos7? }

  describe bash('ls 2>/dev/null /usr/lib64/libfftw*') do
    its('stdout') { should be_empty }
  end

  describe bash('ls 2>/dev/null /usr/lib/libfftw*') do
    its('stdout') { should be_empty }
  end
end
