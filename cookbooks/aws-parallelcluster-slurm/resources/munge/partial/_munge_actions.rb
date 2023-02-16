# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-slurm
# Recipe:: install_munge
#
# Copyright:: 2013-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# Munge
munge_version = node['cluster']['munge']['munge_version']
munge_url = "https://github.com/dun/munge/archive/munge-#{munge_version}.tar.gz"
munge_tarball = "#{node['cluster']['sources_dir']}/munge-#{munge_version}.tar.gz"
munge_user = node['cluster']['munge']['user']
munge_user_id = node['cluster']['munge']['user_id']
munge_group = node['cluster']['munge']['group']
munge_group_id = node['cluster']['munge']['group_id']

action :setup do
  actions = lambda {
    action_purge_packages
    action_download_source_code
    action_compile_and_install
    action_update_init_script
    action_set_user_and_group
    action_create_required_directories
  }
  actions.call unless redhat_ubi?
end

action :purge_packages do
  package %w(munge* libmunge*) do
    action :purge
  end
end

action :download_source_code do
  # Get munge tarball
  remote_file munge_tarball do
    source munge_url
    mode '0644'
    retries 3
    retry_delay 5
    # TODO: Add version or checksum checks
    action :create_if_missing
  end
end

action :compile_and_install do
  # Install munge
  bash 'make install' do
    user 'root'
    group 'root'
    cwd Chef::Config[:file_cache_path]
    code <<-MUNGE
      set -e
      tar xf #{munge_tarball}
      cd munge-munge-#{munge_version}
      ./bootstrap
      ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --libdir=#{munge_libdir}
      CORES=$(grep processor /proc/cpuinfo | wc -l)
      make -j $CORES
      make install
    MUNGE
    not_if "/usr/sbin/munged --version | grep -q munge-#{munge_version} && ls #{munge_libdir}/libmunge*"
  end
end

action :update_init_script do
  # Updated munge init script for Amazon Linux
  template '/etc/init.d/munge' do
    source 'munge/munge-init.erb'
    cookbook 'aws-parallelcluster-slurm'
    owner 'root'
    group 'root'
    variables(munge_user: munge_user,
              munge_group: munge_group)
    mode '0755'
  end
end

action :set_user_and_group do
  # Setup munge group
  group munge_group do
    comment 'munge group'
    gid munge_group_id
    system true
  end

  # Setup munge user
  user munge_user do
    uid munge_user_id
    gid munge_group_id
    manage_home false
    comment 'munge user'
    system true
    shell '/sbin/nologin'
  end
end

action :create_required_directories do
  # Create required directories for munge
  dirs = ["/var/log/munge", "/etc/munge", "/var/run/munge"]
  dirs.each do |dir|
    directory dir do
      action :create
      owner munge_user
      group munge_group
    end
  end
end
