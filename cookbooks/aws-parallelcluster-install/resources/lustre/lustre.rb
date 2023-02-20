# frozen_string_literal: true

#
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
# Default resource implementation
provides :lustre

default_action :setup

action :setup do

  if platform?('centos') && %w(7.5 7.6).include?(node['platform_version'].to_f)
    # Centos 7.6 and 7.5

    lustre_kmod_rpm = "#{node['cluster']['sources_dir']}/kmod-lustre-client-#{node['cluster']['lustre']['version']}.x86_64.rpm"
    lustre_client_rpm = "#{node['cluster']['sources_dir']}/lustre-client-#{node['cluster']['lustre']['version']}.x86_64.rpm"

    # Get Lustre Kernel Module RPM
    remote_file lustre_kmod_rpm do
      source node['cluster']['lustre']['kmod_url']
      mode '0644'
      retries 3
      retry_delay 5
      not_if { ::File.exist?(lustre_kmod_rpm) }
    end

    # Get Lustre Client RPM
    remote_file lustre_client_rpm do
      source node['cluster']['lustre']['client_url']
      mode '0644'
      retries 3
      retry_delay 5
      not_if { ::File.exist?(lustre_client_rpm) }
    end

    # Install lustre mount drivers
    package 'lustre_kmod' do
      source lustre_kmod_rpm
    end

    # Install lustre mount drivers
    package 'lustre_client' do
      source lustre_client_rpm
    end

    kernel_module 'lnet'

  elsif redhat8? || (platform?('centos') && node['platform_version'].to_f >= 7.7)
    # Centos >= 7.7

    # add fsx lustre repository
    yum_repository "aws-fsx" do
      description "AWS FSx Packages - $basearch"
      baseurl node['cluster']['lustre']['base_url']
      gpgkey node['cluster']['lustre']['public_key']
      retries 3
      retry_delay 5
    end

    package %w(kmod-lustre-client lustre-client) do
      retries 3
      retry_delay 5
    end

    kernel_module 'lnet' unless virtualized?

  elsif platform?('centos')
    # Centos 6
    Chef::Log.warn("Unsupported version of Centos, #{node['platform_version']}, supported versions are >= 7.5")

  elsif platform?('ubuntu')

    apt_repository 'fsxlustreclientrepo' do
      uri          node['cluster']['lustre']['base_url']
      components   ['main']
      key          node['cluster']['lustre']['public_key']
      retries 3
      retry_delay 5
    end

    apt_update

    package "lustre-client-modules-#{node['cluster']['kernel_release']}" do
      retries 3
      retry_delay 5
    end unless virtualized?

    package "lustre-client-modules-aws" do
      retries 3
      retry_delay 5
    end

    kernel_module 'lnet' unless virtualized?

  elsif platform?('amazon')

    alinux_extras_topic 'lustre2.10'

  end
end
