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

def kernel_release
  ENV['KERNEL_RELEASE'] || default['cluster']['kernel_release']
end

#
# Retrieve RHEL OS minor version from running kernel version
# The OS minor version is retrieved from the patch version of the running kernel
# following the mapping reported here https://access.redhat.com/articles/3078#RHEL7
# Method works for CentOS7 minor version >=7
#
def find_rhel_minor_version
  os_minor_version = ''

  if node['platform'] == 'centos'
    # kernel release is in the form 3.10.0-1127.8.2.el7.x86_64
    kernel_patch_version = kernel_release.match(/^\d+\.\d+\.\d+-(\d+)\..*$/)
    raise "Unable to retrieve the kernel patch version from #{kernel_release}." unless kernel_patch_version

    case node['platform_version'].to_i
    when 7
      os_minor_version = '7' if kernel_patch_version[1] >= '1062'
      os_minor_version = '8' if kernel_patch_version[1] >= '1127'
      os_minor_version = '9' if kernel_patch_version[1] >= '1160'
    else
      raise "CentOS version #{node['platform_version']} not supported."
    end
  end

  os_minor_version
end

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

# Utility function to add an attribute in GRUB_CMDLINE_LINUX_DEFAULT if it is not present
def append_if_not_present_grub_cmdline(attributes, grub_variable)
  grep_grub_cmdline = 'grep "^' + grub_variable + '=" /etc/default/grub'

  ruby_block "Append #{grub_variable} if it do not exist in /etc/default/grub" do
    block do
      if shell_out(grep_grub_cmdline).stdout.include? "#{grub_variable}="
        Chef::Log.debug("Found #{grub_variable} line")
      else
        Chef::Log.warn("#{grub_variable} not found - Adding")
        shell_out('echo \'' + grub_variable + '=""\' >> /etc/default/grub')
        Chef::Log.info("Added #{grub_variable} line")
      end
    end
    action :run
  end

  attributes.each do |attribute, properties|
    ruby_block "Add #{attribute} with value #{properties['value']} to /etc/default/grub in line #{grub_variable} if it is not present" do
      block do
        command_out = shell_out(grep_grub_cmdline).stdout
        if command_out.include? "#{attribute}"
          Chef::Log.warn("Found #{attribute} in #{grub_variable} - #{grub_variable} value: #{command_out}")
        else
          Chef::Log.info("#{attribute} not found - Adding")
          shell_out('sed -i \'s/^\(' + grub_variable + '=".*\)"$/\1 ' + attribute + '=' + properties['value'] + '"/g\' /etc/default/grub')
          Chef::Log.info("Added #{attribute}=#{properties['value']} to #{grub_variable}")
        end
      end
      action :run
    end
  end
end
