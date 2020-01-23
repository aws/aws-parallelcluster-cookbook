# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: _default_pre
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
  filehandle_limit node['cfncluster']['filehandle_limit']
end

include_recipe 'aws-parallelcluster::_update_packages'

# Reboot after preliminary configuration steps
if !tagged?('rebooted') && node['cfncluster']['default_pre_reboot'] == 'true'
  # On Ubuntu, the /tmp folder is erased by default after a reboot and its lifecycle is managed
  # by different tools, depending on the Ubuntu version
  if node['platform'] == 'ubuntu'
    if node['platform_version'] == "16.04"
      file '/etc/tmpfiles.d/tmp.conf' do
        content 'd /tmp 1777 root root 1d'
      end
    end
  end

  tag('rebooted')
  reboot 'now' do
    action :reboot_now
    delay_mins 1
    reason 'Cannot continue Chef run without a reboot after packages update.'
  end
end

# Remove the configuration to keep the /tmp folder on Ubuntu after a reboot
if tagged?('rebooted')
  if node['platform'] == 'ubuntu'
    if node['platform_version'] == "16.04"
      file '/etc/tmpfiles.d/tmp.conf' do
        action :delete
        only_if { File.exist? '/etc/tmpfiles.d/tmp.conf' }
      end
    end
  end
end
