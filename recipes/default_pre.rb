# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: default_pre
#
# Copyright 2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# Calling user_ulimit will override every existing limit
user_ulimit "*" do
  filehandle_limit node['cluster']['filehandle_limit']
end

include_recipe 'aws-parallelcluster::update_packages'

# Reboot after preliminary configuration steps
if !tagged?('rebooted') && node['cluster']['default_pre_reboot'] == 'true'
  tag('rebooted')
  reboot 'now' do
    action :reboot_now
    delay_mins 1
    reason 'Cannot continue Chef run without a reboot after packages update.'
  end
end
