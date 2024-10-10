# frozen_string_literal: true
#
# Copyright:: 2013-2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

unified_mode true
default_action :setup

action :setup do
  return if on_docker?
  action_install_package

  directory node['cluster']['enroot_dir'] do
    owner 'root'
    group 'root'
    mode '1777'
    action :create
  end

  directory node['cluster']['enroot_cache_path'] do
    owner 'root'
    group 'root'
    mode '1777'
    action :create
  end

  directory "/run/enroot" do
    mode '1777'
    action :create
  end

  directory "/run/enroot/data" do
    mode '1777'
    action :create
  end

  template "/etc/enroot/enroot.conf" do
    source 'enroot/enroot.conf.erb'
    cookbook 'aws-parallelcluster-platform'
    owner 'root'
    group 'root'
    mode '0644'
    action :create
  end
end

def package_version
  node['cluster']['enroot']['version']
end

def enroot_installed
  ::File.exist?('/usr/bin/enroot')
end
