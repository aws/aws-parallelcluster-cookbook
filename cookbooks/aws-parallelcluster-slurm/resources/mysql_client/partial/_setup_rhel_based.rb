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
  mysql_archive_url = package_archive(node['cluster']['artifacts_s3_url'])
  mysql_tar_file = "/tmp/#{package_filename}"

  log "Downloading MySQL packages archive from #{mysql_archive_url}"

  # Add MySQL source file
  action_create_source_link

  remote_file mysql_tar_file do
    source mysql_archive_url
    mode '0644'
    retries 3
    retry_delay 5
    action :create_if_missing
  end

  bash 'Install MySQL packages' do
    user 'root'
    group 'root'
    cwd '/tmp'
    code <<-MYSQL
        set -e

        EXTRACT_DIR=$(mktemp -d --tmpdir mysql.XXXXXXX)
        tar xf "#{mysql_tar_file}" --directory "${EXTRACT_DIR}"
        yum install -y ${EXTRACT_DIR}/*
    MYSQL
  end
end

action_class do
  def package_platform
    platform_version = node['platform_version'].to_i
    if platform_version == 2
      platform_version = 7
    end
    arm_instance? ? "el/#{platform_version}/aarch64" : "el/#{platform_version}/x86_64"
  end

  def repository_packages
    %w(mysql-community-devel mysql-community-libs mysql-community-common mysql-community-client-plugins mysql-community-libs-compat)
  end
end
