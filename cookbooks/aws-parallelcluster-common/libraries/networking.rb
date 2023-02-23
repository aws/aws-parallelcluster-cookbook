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

# Return the VPC CIDR list from node info
def get_vpc_cidr_list
  mac = node['ec2']['mac']
  vpc_cidr_list = node['ec2']['network_interfaces_macs'][mac]['vpc_ipv4_cidr_blocks']
  vpc_cidr_list.split(/\n+/)
end

class Networking
  # Putting functions in a class makes them easier to mock
  def self.efa_installed?(_node)
    dir_exist = ::Dir.exist?('/opt/amazon/efa')
    if dir_exist
      modinfo_efa_stdout = Mixlib::ShellOut.new("modinfo efa").run_command.stdout
      efa_installed_packages_file = Mixlib::ShellOut.new("cat /opt/amazon/efa_installed_packages").run_command.stdout
      Chef::Log.info("`/opt/amazon/efa` directory already exists. \nmodinfo efa stdout: \n#{modinfo_efa_stdout} \nefa_installed_packages_file_content: \n#{efa_installed_packages_file}")
    end
    dir_exist
  end

  def self.efa_supported?(node)
    !Helpers.arm_instance?(node) || !node['cluster']['efa']['unsupported_aarch64_oses'].include?(node['cluster']['base_os'])
  end
end

def efa_installed?
  Networking.efa_installed?(node)
end

def efa_supported?
  Networking.efa_supported?(node)
end
