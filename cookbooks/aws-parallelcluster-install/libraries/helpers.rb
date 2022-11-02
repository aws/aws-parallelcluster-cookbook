# frozen_string_literal: true

# Copyright:: 2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

#
# Disable service
#
def disable_service(service, platform_families = node['platform_family'], operations = :disable)
  if platform_family?(platform_families)
    service service do
      action operations
    end
  end
end

def get_package_version(package_name)
  cmd = value_for_platform(
  'default' => "rpm -qi #{package_name} | grep Version | awk '{print $3}'",
  'ubuntu' => { "default" => "dpkg-query --showformat='${Version}' --show #{package_name} | awk -F- '{print $1}'" }) # TODO: These commands do not fit all packages versions. e.g. dpkg-query --showformat='${Version}' --show stunnel4 | awk -F- '{print $1}'   Output:3:5.63
  package_version_cmd = Mixlib::ShellOut.new(cmd)
  version = package_version_cmd.run_command.stdout.strip
  if version.empty?
    Chef::Log.info("#{package_name} not found when trying to get the version.")
  end
  version
end

def validate_file_hash(file_path, expected_hash)
  hash_function = yield
  checksum = hash_function.file(file_path).hexdigest
  if checksum != expected_hash
    raise "Downloaded file #{file_path} checksum #{checksum} does not match expected checksum #{expected_hash}"
  end
end

def validate_file_md5_hash(file_path, expected_hash)
  validate_file_hash(file_path, expected_hash) do
    require 'digest'
    Digest::MD5
  end
end

def validate_file_sha256_hash(file_path, expected_hash)
  validate_file_hash(file_path, expected_hash) do
    require 'digest'
    Digest::SHA2.new(256)
  end
end

def install_repository_definition(repository_name, definition_source, local_file, md5_hash = nil)
  remote_file local_file do
    source definition_source
    mode '0644'
    retries 3
    retry_delay 5
    not_if { ::File.exist?(local_file) }
  end

  ruby_block "Validate Repository Definition Checksum" do
    block do
      validate_file_md5_hash(local_file, md5_hash = nil)
    end
    not_if { md5_hash.nil? }
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
