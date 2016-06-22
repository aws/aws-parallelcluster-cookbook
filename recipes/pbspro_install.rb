#
# Cookbook Name:: cfncluster
# Recipe:: pbspro_install
#
# Copyright 2013-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Amazon Software License (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/asl/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

include_recipe 'cfncluster::base_install'

pbspro_tarball = "#{node['cfncluster']['sources_dir']}/pbspro-#{node['cfncluster']['pbspro']['version']}.tar.gz"

# Get pbspro tarball
remote_file pbspro_tarball do
  source node['cfncluster']['pbspro']['url']
  mode '0644'
  # TODO: Add version or checksum checks
  not_if { ::File.exist?(pbspro_tarball) }
end

case node['platform']
when 'centos', 'redhat', 'scientific' # ~FC024

# Install pbspro
bash 'make install' do
  user 'root'
  group 'root'
  cwd Chef::Config[:file_cache_path]
  code <<-EOF
    tar xf #{pbspro_tarball}
    cd pbspro-#{node['cfncluster']['pbspro']['version']}
    ./configure --prefix=/opt/pbs
    CORES=$(grep processor /proc/cpuinfo | wc -l)
    make -j $CORES
    make install
  EOF
  # Only perform if running version doesn't match desired
  not_if "/opt/pbs/bin/pbsnodes --version 2>&1 | grep -q #{node['cfncluster']['torque']['version']}"
  creates "/random/path"
end

when 'amazon'

libical_tarball = "#{node['cfncluster']['sources_dir']}/libical-#{node['cfncluster']['pbspro']['libical_version']}.tar.gz"

# Get libical tarball
remote_file libical_tarball do
  source node['cfncluster']['pbspro']['libical_url']
  mode '0644'
  # TODO: Add version or checksum checks
  not_if { ::File.exist?(libical_tarball) }
end

# Install libical
bash 'cmake install' do
  user 'root'
  group 'root'
  cwd Chef::Config[:file_cache_path]
  code <<-EOF
    tar xf #{libical_tarball}
    cd libical-#{node['cfncluster']['pbspro']['libical_version']}
    mkdir build
    cd build
    cmake -DCMAKE_C_FLAGS_RELEASE:STRING=-DNDEBUG -DCMAKE_CXX_FLAGS_RELEASE:STRING=-DNDEBUG -DCMAKE_Fortran_FLAGS_RELEASE:STRING=-DNDEBUG -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON -DCMAKE_INSTALL_PREFIX:PATH=/usr -DINCLUDE_INSTALL_DIR:PATH=/usr/include -DLIB_INSTALL_DIR:PATH=/usr/lib64 -DSYSCONF_INSTALL_DIR:PATH=/etc -DSHARE_INSTALL_PREFIX:PATH=/usr/share -DLIB_SUFFIX=64 -DBUILD_SHARED_LIBS:BOOL=ON ..
    CORES=$(grep processor /proc/cpuinfo | wc -l)
    make -j $CORES
    make install
  EOF
  creates '/usr/lib64/pkgconfig/libical.pc'
end

##

tk_tarball = "#{node['cfncluster']['sources_dir']}/tk-#{node['cfncluster']['pbspro']['tk_version']}.tar.gz"

# Get tk tarball
remote_file tk_tarball do
  source node['cfncluster']['pbspro']['tk_url']
  mode '0644'
  # TODO: Add version or checksum checks
  not_if { ::File.exist?(tk_tarball) }
end

# Install tk
bash 'make install' do
  user 'root'
  group 'root'
  cwd Chef::Config[:file_cache_path]
  code <<-EOF
    tar xf #{tk_tarball}
    cd tk#{node['cfncluster']['pbspro']['tk_version']}/unix
    ./configure --host=x86_64-redhat-linux --build=x86_64-redhat-linux --program-prefix= --disable-dependency-tracking --prefix=/usr --exec-prefix=/usr --bindir=/usr/bin --sbindir=/usr/sbin --sysconfdir=/etc --datadir=/usr/share --includedir=/usr/include --libdir=/usr/lib64 --libexecdir=/usr/libexec --localstatedir=/var --sharedstatedir=/var/lib --mandir=/usr/share/man --infodir=/usr/share/info
    CORES=$(grep processor /proc/cpuinfo | wc -l)
    make -j $CORES TK_LIBRARY=/usr/share/tk8.5
    make install TK_LIBRARY=/usr/share/tk8.5
  EOF
  creates '/usr/lib64/tkConfig.sh'
end

# Install pbspro
bash 'make install' do
  user 'root'
  group 'root'
  cwd Chef::Config[:file_cache_path]
  code <<-EOF
    tar xf #{pbspro_tarball}
    cd pbspro-#{node['cfncluster']['pbspro']['version']}
    ./configure --prefix=/opt/pbs
    CORES=$(grep processor /proc/cpuinfo | wc -l)
    make -j $CORES
    make install
  EOF
  ## Only perform if running version doesn't match desired
  #not_if "/opt/pbs/bin/pbsnodes --version 2>&1 | grep -q #{node['cfncluster']['torque']['version']}"
  creates '/opt/pbs/bin/pbsnodes'
end

end
