# frozen_string_literal: true

#
# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

action :set_udev_autoreload do
  # allow udev to do network call
  execute 'udev-daemon-reload' do
    command 'udevadm control --reload'
    action :nothing
  end

  directory '/etc/systemd/system/systemd-udevd.service.d'

  # Disable udev network sandbox and notify udev to reload configuration
  cookbook_file 'udev-override.conf' do
    source 'ec2_udev_rules/udev-override.conf'
    path '/etc/systemd/system/systemd-udevd.service.d/override.conf'
    user 'root'
    group 'root'
    mode '0644'
    notifies :run, "execute[udev-daemon-reload]", :immediately unless docker?
  end
end
