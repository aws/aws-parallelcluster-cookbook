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

unified_mode true
default_action :setup

action :setup do
  return unless node['cluster']['nvidia']['enabled'] == 'yes' || node['cluster']['nvidia']['enabled'] == true

  gdrcopy_version = node['cluster']['nvidia']['gdrcopy']['version']
  gdrcopy_tarball = "#{node['cluster']['sources_dir']}/gdrcopy-#{gdrcopy_version}.tar.gz"
  gdrcopy_checksum = node['cluster']['nvidia']['gdrcopy']['sha256']

  remote_file gdrcopy_tarball do
    source node['cluster']['nvidia']['gdrcopy']['url']
    mode '0644'
    retries 3
    retry_delay 5
    action :create_if_missing
  end

  ruby_block "Validate NVIDIA GDRCopy Tarball Checksum" do
    block do
      require 'digest'
      checksum = Digest::SHA256.file(gdrcopy_tarball).hexdigest
      raise "Downloaded NVIDIA GDRCopy Tarball Checksum #{checksum} does not match expected checksum #{gdrcopy_checksum}" if checksum != gdrcopy_checksum
    end
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
    cd gdrcopy-#{gdrcopy_version}/packages
    #{installation_code}
    GDRCOPY_INSTALL
  end

  service node['cluster']['nvidia']['gdrcopy']['service'] do
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

action_class do
  def gdrcopy_version_extended
    "#{node['cluster']['nvidia']['gdrcopy']['version']}-1"
  end
end
