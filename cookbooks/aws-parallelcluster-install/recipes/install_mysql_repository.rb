# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: mysql
#
# Copyright:: 2013-2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

def install_repository_configuration_package(repository_name, definition_source, local_file, md5_hash)
  remote_file local_file do
    source definition_source
    mode '0644'
    retries 3
    retry_delay 5
    not_if { ::File.exist?(local_file) }
  end

  ruby_block "Validate Repository Definition Checksum" do
    block do
      require 'digest'
      checksum = Digest::MD5.file(local_file).hexdigest

      if checksum != md5_hash
        raise "Downloaded file #{local_file} checksum #{checksum} does not match expected checksum #{md5_hash}"
      end
    end
  end

  if platform?('ubuntu')
    # dpkg_package is used here because 'package' seems to default to using apt_package
    # which fails on the MySQL package.
    dpkg_package repository_name do
      source local_file
    end

    apt_update 'update' do
      action :update
      retries 3
      retry_delay 5
    end
  else
    package repository_name do
      source local_file
    end
  end
end

unless platform?('ubuntu') && arm_instance?
  install_repository_configuration_package(
    "MySQL Repository",
    node['cluster']['mysql']['repository']['definition']['url'],
    "/tmp/#{node['cluster']['mysql']['repository']['definition']['file-name']}",
    node['cluster']['mysql']['repository']['definition']['md5']
  )
end
