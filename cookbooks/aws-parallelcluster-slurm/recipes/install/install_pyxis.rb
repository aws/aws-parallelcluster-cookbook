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
pyxis_url = "https://github.com/NVIDIA/pyxis/archive/refs/tags/v#{pyxis_version}.tar.gz"
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
    mkdir -p /opt/slurm/etc/plugstack.conf.d
    echo -e 'include /opt/slurm/etc/plugstack.conf.d/*' | tee /opt/slurm/etc/plugstack.conf
    ln -fs /usr/local/share/pyxis/pyxis.conf /opt/slurm/etc/plugstack.conf.d/pyxis.conf
  PYXIS_INSTALL
  retries 3
  retry_delay 5
end
