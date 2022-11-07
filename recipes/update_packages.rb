# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: update_packages
#
# Copyright 2013-2017 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

case node['platform_family']
when 'rhel', 'amazon'
  execute 'yum-update' do
    command "yum -y update && package-cleanup -y --oldkernels --count=1"
  end
when 'debian'
  execute 'install-efibootmanager' do # temporary workaround to solve https://bugs.launchpad.net/ubuntu/+source/grub2-signed/+bug/1936857
    command "apt-get -y install efibootmgr"
    only_if { arm_instance? }
  end
  apt_update
  execute 'apt-upgrade' do
    command "DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::=\"--force-confdef\" -o Dpkg::Options::=\"--force-confold\" --with-new-pkgs upgrade && apt-get autoremove -y"
    retries 3
    retry_delay 5
  end
  package 'linux-aws' do
    retries 3
    retry_delay 5
  end
end
