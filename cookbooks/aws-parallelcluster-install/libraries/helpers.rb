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
  'ubuntu' => { "default" => "dpkg-query --showformat='${Version}' --show #{package_name} | awk -F- '{print $1}'" })
  package_version_cmd = Mixlib::ShellOut.new(cmd)
  version = package_version_cmd.run_command.stdout.strip
  if version.empty?
    Chef::Log.info("#{package_name} not found when trying to get the version.")
  end
  version
end
