# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: intel
#
# Copyright:: 2013-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

if node['cluster']['base_os'] == 'centos7'
  bash 'download dependencies Intel HPC platform' do
    code <<-INTEL
      yum install --downloadonly #{node['cluster']['intelhpc']['dependencies'].join(' ')} --downloaddir=#{node['cluster']['sources_dir']}
      yum makecache -y
    INTEL
  end
end
