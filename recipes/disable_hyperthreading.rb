# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: disable_hyperthreading
#
# Copyright 2013-2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# This recipe should only be run when disabling hyperthreading is
# desired and the instance type doesn't support doing so via CPU
# options (e.g., *.metal instances).
return unless node['cluster']['disable_hyperthreading_manually'] == 'true'

script_path = "#{node['cluster']['scripts_dir']}/disable_hyperthreading_manually.sh"
cookbook_file 'disable_hyperthreading_manually.sh' do
  path script_path
  owner 'root'
  group 'root'
  mode '0744'
end

execute 'disable hyperthreading manually' do
  command script_path
  user 'root'
end
