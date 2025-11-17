# frozen_string_literal: true

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

provides :efs, platform: 'redhat' do |node|
  node['platform_version'].to_i >= 8
end

use 'partial/_get_package_version_rpm'
use 'partial/_common'
use 'partial/_redhat_based'
use 'partial/_install_from_tar'
use 'partial/_mount_umount'

def adc_install_script_code(efs_utils_tarball, efs_utils_package, efs_utils_version)
  <<-EFSUTILSINSTALL
      set -e
      tar xf #{efs_utils_tarball}
      mv efs-proxy-dependencies-#{efs_utils_version}.tar.gz efs-utils-#{efs_utils_version}/src/proxy/
      cd efs-utils-#{efs_utils_version}/src/proxy/
      tar -xf efs-proxy-dependencies-#{efs_utils_version}.tar.gz
      cargo build --offline
      cd ../..
      make rpm
      yum -y install ./build/#{efs_utils_package}*rpm
  EFSUTILSINSTALL
end

def prerequisites
  %w(rpm-build make rust go cargo openssl-devel cmake perl)
end

action :install_efs_utils do
  package_name = "amazon-efs-utils"
  package_version = _efs_utils_version
  efs_utils_tarball = "#{node['cluster']['sources_dir']}/efs-utils-#{package_version}.tar.gz"

  if aws_region.start_with?("us-iso")

    efs_proxy_deps = "efs-proxy-dependencies-#{package_version}.tar.gz"
    efs_proxy_deps_tarball = "#{node['cluster']['sources_dir']}/#{efs_proxy_deps}"
    efs_proxy_deps_url = "#{node['cluster']['artifacts_s3_url']}/dependencies/efs/#{efs_proxy_deps}"
    remote_file efs_proxy_deps_tarball do
      source efs_proxy_deps_url
      mode '0644'
      retries 3
      retry_delay 5
      action :create_if_missing
    end

    bash "install efs utils" do
      cwd node['cluster']['sources_dir']
      code adc_install_script_code(efs_utils_tarball, package_name, package_version)
    end

  else
    # Install EFS Utils following https://docs.aws.amazon.com/efs/latest/ug/installing-amazon-efs-utils.html
    bash "install efs utils" do
      cwd node['cluster']['sources_dir']
      code install_script_code(efs_utils_tarball, package_name, package_version)
    end
  end

  action_increase_poll_interval
end
