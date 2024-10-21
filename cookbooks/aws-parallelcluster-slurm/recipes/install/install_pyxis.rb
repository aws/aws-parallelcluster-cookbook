# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-slurm
# Recipe:: install_pyxis
#
# Copyright:: 2024 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
return if pyxis_installed?

pyxis_version = node['cluster']['pyxis']['version']
pyxis_url = "#{node['cluster']['artifacts_s3_url']}/dependencies/pyxis/v#{pyxis_version}.tar.gz"
pyxis_tarball = "#{node['cluster']['sources_dir']}/pyxis-#{pyxis_version}.tar.gz"

spank_examples_dir = "#{node['cluster']['examples_dir']}/spank"
pyxis_examples_dir = "#{node['cluster']['examples_dir']}/pyxis"

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
    CPPFLAGS='-I #{node['cluster']['slurm']['install_dir']}/include/' make
    CPPFLAGS='-I #{node['cluster']['slurm']['install_dir']}/include/' make install
  PYXIS_INSTALL
  retries 3
  retry_delay 5
end

# Spank configurations

directory spank_examples_dir

template "#{spank_examples_dir}/plugstack.conf" do
  source 'pyxis/plugstack.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

# Pyxis configurations

directory pyxis_examples_dir

template "#{pyxis_examples_dir}/pyxis.conf" do
  source 'pyxis/pyxis.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end
