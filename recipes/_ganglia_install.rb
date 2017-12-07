#
# Cookbook Name:: cfncluster
# Recipe:: _ganglia_install
#
# Copyright 2013-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

case node['platform']
when "redhat", "centos", "amazon", "scientific" # ~FC024

  package "httpd"
  package "apr-devel"
  package "libconfuse-devel"
  package "expat-devel"
  package "rrdtool-devel"
  package "pcre-devel"
  package "php"
  package "php-gd"

  # Get Ganglia tarball
  ganglia_tarball = "#{node['cfncluster']['sources_dir']}/monitor-core-#{node['cfncluster']['ganglia']['version']}.tar.gz"
  remote_file ganglia_tarball do
    source node['cfncluster']['ganglia']['url']
    mode '0644'
    # TODO: Add version or checksum checks
    not_if { ::File.exist?(ganglia_tarball) }
  end

  ##
  # Install Ganglia
  bash 'make install' do
    user 'root'
    group 'root'
    cwd Chef::Config[:file_cache_path]
    code <<-GANGLIA
      tar xf #{ganglia_tarball}
      cd monitor-core-#{node['cfncluster']['ganglia']['version']}
      ./bootstrap
      ./configure --build=x86_64-redhat-linux-gnu --host=x86_64-redhat-linux-gnu --program-prefix= --disable-dependency-tracking \
      --prefix=/usr --exec-prefix=/usr --bindir=/usr/bin --sbindir=/usr/sbin --sysconfdir=/etc --datadir=/usr/share --includedir=/usr/include \
      --libdir=/usr/lib64 --libexecdir=/usr/libexec --localstatedir=/var --sharedstatedir=/var/lib --mandir=/usr/share/man \
      --infodir=/usr/share/info --with-gmetad --enable-status --sysconfdir=/etc/ganglia
      CORES=$(grep processor /proc/cpuinfo | wc -l)
      make -j $CORES
      make install
    GANGLIA
    # TODO: Fix, so it works for upgrade
    creates '/usr/sbin/gmetad'
  end

  if node['init_package'] == 'init'
    # Setup init.d scripts if not systemd
    execute "copy gmetad init script" do
      command "cp " \
        "#{Chef::Config[:file_cache_path]}/monitor-core-#{node['cfncluster']['ganglia']['version']}/gmetad/gmetad.init " \
        "/etc/init.d/gmetad"
      not_if "test -f /etc/init.d/gmetad"
    end
    execute "copy gmmond init script" do
      command "cp " \
        "#{Chef::Config[:file_cache_path]}/monitor-core-#{node['cfncluster']['ganglia']['version']}/gmond/gmond.init " \
        "/etc/init.d/gmond"
      not_if "test -f /etc/init.d/gmond"
    end
  end

  # Reload systemd
  execute 'systemctl-daemon-reload' do
    command '/bin/systemctl --system daemon-reload'
    only_if "test -f /bin/systemctl"
  end

  # Get Ganglia Web tarball
  ganglia_web_tarball = "#{node['cfncluster']['sources_dir']}/ganglia-web-#{node['cfncluster']['ganglia']['web_version']}.tar.gz"
  remote_file ganglia_web_tarball do
    source node['cfncluster']['ganglia']['web_url']
    mode '0644'
    # TODO: Add version or checksum checks
    not_if { ::File.exist?(ganglia_web_tarball) }
  end

  ##
  # Install Ganglia Web
  bash 'make install' do
    user 'root'
    group 'root'
    cwd Chef::Config[:file_cache_path]
    code <<-GANGLIAWEB
      tar xf #{ganglia_web_tarball}
      cd ganglia-web-#{node['cfncluster']['ganglia']['web_version']}
      make install APACHE_USER=#{node['cfncluster']['ganglia']['apache_user']}
    GANGLIAWEB
    # TODO: Fix, so it works for upgrade
    creates '/usr/share/ganglia-webfrontend/index.php'
  end

  cookbook_file 'ganglia-webfrontend.conf' do
    path '/etc/httpd/conf.d/ganglia-webfrontend.conf'
    user 'root'
    group 'root'
    mode '0644'
  end

  directory '/var/lib/ganglia/rrds' do
    owner 'nobody'
    group 'nobody'
    mode 0755
    recursive true
    action :create
  end

  # Copy required licensing files
  directory "#{node['cfncluster']['license_dir']}/ganglia"

  bash 'copy license stuff' do
    user 'root'
    group 'root'
    cwd Chef::Config[:file_cache_path]
    code <<-GANGLIALICENSE
      cd monitor-core-#{node['cfncluster']['ganglia']['version']}
      cp -v COPYING #{node['cfncluster']['license_dir']}/ganglia/COPYING
    GANGLIALICENSE
    # TODO: Fix, so it works for upgrade
    creates "#{node['cfncluster']['license_dir']}/ganglia/COPYING"
  end

when "ubuntu"

  package "ganglia-monitor"
  package "rrdtool"
  package "gmetad"
  package "ganglia-webfrontend"

  # Setup ganglia-web.conf apache config
  execute "copy ganglia apache conf" do
    command "cp /etc/ganglia-webfrontend/apache.conf /etc/apache2/sites-enabled/ganglia.conf"
    not_if "test -f /etc/apache2/sites-enabled/ganglia.conf"
  end

end
