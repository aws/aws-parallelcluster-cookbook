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

action :setup do
  # Add MySQL source file
  action_create_source_link

  # Download the individual MySQL community client RPMs from base_url and
  # install them in a single yum transaction so interdependencies resolve.
  # (Previously a single .tar.gz bundle was downloaded and extracted; the RPMs
  # are now stored unbundled, so base_url can point at either the PCluster S3
  # mirror or MySQL's public yum repo using ExtraChefAttributes.
  rpm_files = mysql_rpm_filenames

  rpm_files.each do |rpm|
    remote_file "/tmp/#{rpm}" do
      source "#{package_base_url}/#{rpm}"
      mode '0644'
      retries 3
      retry_delay 5
      action :create_if_missing
    end
  end

  bash 'Install MySQL packages' do
    user 'root'
    group 'root'
    cwd '/tmp'
    code <<-MYSQL
        set -e
        yum install -y #{rpm_files.join(' ')}
    MYSQL
  end
end

action_class do
  def el_version
    platform_version = node['platform_version'].to_i
    if platform_version == 2023
      9
    else
      platform_version
    end
  end

  def rpm_arch
    arm_instance? ? 'aarch64' : 'x86_64'
  end

  def package_platform
    "el/#{el_version}/#{rpm_arch}"
  end

  # base_url + platform path holding the individual RPMs.
  def package_base_url
    "#{node['cluster']['mysql']['base_url']}/#{package_platform}"
  end

  # MySQL community client RPM filenames for this platform/arch.
  def mysql_rpm_components
    %w(common client-plugins libs devel)
  end

  def mysql_rpm_filenames
    mysql_rpm_components.map do |component|
      "mysql-community-#{component}-#{node['cluster']['mysql']['version']}.el#{el_version}.#{rpm_arch}.rpm"
    end
  end
end
