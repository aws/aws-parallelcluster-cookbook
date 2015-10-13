include_recipe 'cfncluster::base_install'

if platform?( "redhat", "centos", "amazon" )
  package "httpd"
  package "apr-devel"
  package "libconfuse-devel"
  package "expat-devel"
  package "rrdtool-devel"
  package "pcre-devel"
end

ganglia_tarball = "#{node['cfncluster']['sources_dir']}/ganglia-#{node['cfncluster']['ganglia']['version']}.tar.gz"

# Get Ganglia tarball
remote_file ganglia_tarball do
  source node['cfncluster']['ganglia']['url']
  mode '0644'
  # TODO: Add version or checksum checks
  not_if { ::File.exists?(ganglia_tarball) }
end

ganglia_web_tarball = "#{node['cfncluster']['sources_dir']}/ganglia-web-#{node['cfncluster']['ganglia']['web_version']}.tar.gz"

# Get Ganglia Web tarball
remote_file ganglia_web_tarball do
  source node['cfncluster']['ganglia']['web_url']
  mode '0644'
  # TODO: Add version or checksum checks
  not_if { ::File.exists?(ganglia_web_tarball) }
end

# Install Ganglia
bash 'make install' do
  user 'root'
  group 'root'
  cwd Chef::Config[:file_cache_path]
  code <<-EOF
    tar xf #{ganglia_tarball}
    cd ganglia-#{node['cfncluster']['ganglia']['version']}
    ./configure --with-gmetad --enable-status --sysconfdir=/etc/ganglia --prefix=/usr
    make install
  EOF
  # TODO: Fix, so it works for upgrade
  creates '/usr/sbin/gmetad'
end

# Setup init.d scripts
case node['platform']
when "redhat", "centos", "amazon"
  execute "copy gmetad init script" do
    command "cp " +
      "#{Chef::Config[:file_cache_path]}/ganglia-#{node['cfncluster']['ganglia']['version']}/gmetad/gmetad.init " +
      "/etc/init.d/gmetad"
    not_if "test -f /etc/init.d/gmetad"
  end
  execute "copy gmmond init script" do
    command "cp " +
      "#{Chef::Config[:file_cache_path]}/ganglia-#{node['cfncluster']['ganglia']['version']}/gmond/gmond.init " +
      "/etc/init.d/gmond"
    not_if "test -f /etc/init.d/gmond"
  end
end

# Install Ganglia Web
bash 'make install' do
  user 'root'
  group 'root'
  cwd Chef::Config[:file_cache_path]
  code <<-EOF
    tar xf #{ganglia_web_tarball}
    cd ganglia-web-#{node['cfncluster']['ganglia']['web_version']}
    make install APACHE_USER=apache
  EOF
  # TODO: Fix, so it works for upgrade
  creates '/usr/share/ganglia-webfrontend/index.php'
end

# Setup ganglia-web.conf apache config
case node['platform']
when "redhat", "centos", "amazon"
  execute "copy ganglia apache conf" do
    command "cp " +
      "#{Chef::Config[:file_cache_path]}/ganglia-web-#{node['cfncluster']['ganglia']['web_version']}/apache.conf " +
      "/etc/httpd/conf.d/ganglia-webfrontend.conf"
    not_if "test -f /etc/httpd/conf.d/ganglia-webfrontend.conf"
  end
end

