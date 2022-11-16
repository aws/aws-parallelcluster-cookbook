# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: nfs
#
# Copyright:: 2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

node.force_override['nfs']['threads'] = node['cluster']['nfs']['threads']

# Overwriting templates for node['nfs']['config']['server_template'] used by NFS cookbook for these OSs
# When running, NFS cookbook will use nfs.conf.erb templates provided in this cookbook to generate server_template
edit_resource(:template, node['nfs']['config']['server_template']) do
  source 'nfs/nfs.conf.erb'
  cookbook 'aws-parallelcluster-config'
end

# Explicitly restart NFS server for thread setting to take effect
# and enable it to start at boot
service node['nfs']['service']['server'] do
  action %i(restart enable)
  supports restart: true
end
