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

property :gdrcopy_version, String, default: '2.3'
property :gdrcopy_checksum, String, default: 'b85d15901889aa42de6c4a9233792af40dd94543e82abe0439e544c87fd79475'

unified_mode true
default_action :setup

action :setup do
  return unless gdrcopy_enabled?

  # Save gdrcopy version for InSpec tests
  node.default['cluster']['nvidia']['gdrcopy']['version'] = new_resource.gdrcopy_version
  node.default['cluster']['nvidia']['gdrcopy']['service'] = gdrcopy_service
  node_attributes 'dump node attributes'

  gdrcopy_tarball = "#{node['cluster']['sources_dir']}/gdrcopy-#{new_resource.gdrcopy_version}.tar.gz"

  directory node['cluster']['sources_dir'] do
    recursive true
  end

  remote_file gdrcopy_tarball do
    source gdrcopy_url
    mode '0644'
    retries 3
    retry_delay 5
    checksum new_resource.gdrcopy_checksum
    action :create_if_missing
  end

  package_repos 'update package repos' do
    action :update
  end

  package gdrcopy_build_dependencies do
    retries 3
    retry_delay 5
  end

  bash 'Install NVIDIA GDRCopy' do
    user 'root'
    group 'root'
    cwd Chef::Config[:file_cache_path]
    code <<-GDRCOPY_INSTALL
    set -e
    tar -xf #{gdrcopy_tarball}
    cd gdrcopy-#{new_resource.gdrcopy_version}/packages
    #{installation_code}
    GDRCOPY_INSTALL
  end

  service gdrcopy_service do
    action %i(disable stop)
  end
end

action :verify do
  %w(copybw).each do |command|
    bash "Verify NVIDIA GDRCopy: #{command}" do
      user 'root'
      group 'root'
      cwd Chef::Config[:file_cache_path]
      code <<-GDRCOPY_VERIFY
      set -e
      #{command}
      GDRCOPY_VERIFY
    end
  end
end

action :configure do
  # Save gdrcopy version for InSpec tests
  node.default['cluster']['nvidia']['gdrcopy']['version'] = new_resource.gdrcopy_version
  node.default['cluster']['nvidia']['gdrcopy']['service'] = gdrcopy_service
  node_attributes 'dump node attributes'

  if graphic_instance? && is_service_installed?(gdrcopy_service)
    # NVIDIA GDRCopy
    execute "enable #{gdrcopy_service} service" do
      # Using command in place of service resource because of: https://github.com/chef/chef/issues/12053
      command "systemctl enable #{gdrcopy_service}"
    end
    service gdrcopy_service do
      action :start
      supports status: true
    end
  end
end

def gdrcopy_version_extended
  "#{gdrcopy_version}-1"
end

def gdrcopy_url
  "https://github.com/NVIDIA/gdrcopy/archive/refs/tags/v#{gdrcopy_version}.tar.gz"
end
