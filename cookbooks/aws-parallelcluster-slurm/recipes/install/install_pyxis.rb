# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-slurm
# Recipe:: install_pyxis
#
# Copyright:: Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

return unless nvidia_enabled?

pyxis_version = node['cluster']['pyxis']['version']
pyxis_url = "#{node['cluster']['artifacts_s3_url']}/dependencies/pyxis/v#{pyxis_version}.tar.gz"
pyxis_tarball = "#{node['cluster']['sources_dir']}/pyxis-#{pyxis_version}.tar.gz"

remote_file pyxis_tarball do
  source pyxis_url
  mode '0644'
  retries 3
  retry_delay 5
  action :create_if_missing
end

bash "Install pyxis" do
  user 'root'
  code <<-PYXIS_INSTALL
    set -e
    tar xf #{pyxis_tarball} -C /tmp
    cd /tmp/pyxis-#{pyxis_version}
    CPPFLAGS='-I /opt/slurm/include/' make
    CPPFLAGS='-I /opt/slurm/include/' make install
  PYXIS_INSTALL
  retries 3
  retry_delay 5
end

directory "#{node['cluster']['slurm']['install_dir']}/etc" do
  user 'root'
  group 'root'
  mode '0755'
end

directory "#{node['cluster']['slurm']['install_dir']}/etc/plugstack.conf.d"

directory node['cluster']['config_examples_dir']

directory "#{node['cluster']['config_examples_dir']}/spank"

directory "#{node['cluster']['config_examples_dir']}/pyxis"

directory "/run/pyxis" do
  owner node['cluster']['cluster_user']
  # group node['cluster']['cluster_user']
  mode '1777'
  action :create
end

template "#{node['cluster']['config_examples_dir']}/spank/plugstack.conf" do
  source 'pyxis/plugstack.conf.erb'
  cookbook 'aws-parallelcluster-slurm'
  owner 'root'
  group 'root'
  mode '0644'
end

link '/usr/local/share/pyxis/pyxis.conf' do
  to "#{node['cluster']['slurm']['install_dir']}/etc/plugstack.conf.d/pyxis.conf"
end

template "#{node['cluster']['config_examples_dir']}/pyxis/pyxis.conf" do
  source 'pyxis/pyxis.conf.erb'
  cookbook 'aws-parallelcluster-platform'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    pyxis_persistent_runtime_path: "/run/pyxis"
  )
end
