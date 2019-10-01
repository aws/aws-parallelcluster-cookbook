#
# Cookbook Name:: aws-parallelcluster
# Recipe:: _ec2_udev_rules
#
# Copyright 2013-2015 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

template 'ec2-volid.rules' do
  source 'ec2-volid.rules.erb'
  path '/etc/udev/rules.d/52-ec2-volid.rules'
  user 'root'
  group 'root'
  mode '0644'
end

cookbook_file 'parallelcluster-ebsnvme-id' do
  path '/usr/local/sbin/parallelcluster-ebsnvme-id'
  user 'root'
  group 'root'
  mode '0744'
end

cookbook_file 'ec2_dev_2_volid.py' do
  path '/sbin/ec2_dev_2_volid.py'
  user 'root'
  group 'root'
  mode '0744'
end

cookbook_file 'ec2blkdev-init' do
  path '/etc/init.d/ec2blkdev'
  user 'root'
  group 'root'
  mode '0744'
end

cookbook_file 'attachVolume.py' do
  path '/usr/local/sbin/attachVolume.py'
  user 'root'
  group 'root'
  mode '0755'
end

if node['platform'] == 'ubuntu' && node['platform_version'] == "18.04"
  # allow Ubuntu 18 udev to do network call
  execute 'udev-daemon-reload' do
    command 'udevadm control --reload'
    action :nothing
  end

  directory '/etc/systemd/system/systemd-udevd.service.d'

  # Disable udev network sandbox and notify udev to reload configuration
  cookbook_file 'udev-override.conf' do
    path '/etc/systemd/system/systemd-udevd.service.d/override.conf'
    user 'root'
    group 'root'
    mode '0644'
    notifies :run, "execute[udev-daemon-reload]", :immediately
  end
end

service "ec2blkdev" do
  supports restart: true
  action %i[enable start]
end
