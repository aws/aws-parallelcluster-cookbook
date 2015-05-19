#
# Cookbook Name:: cfncluster
# Recipe:: _prep_env
#
# Copyright (c) 2015 Amazon Web Services, All Rights Reserved.

directory '/etc/cfncluster'
directory '/opt/cfncluster'
directory '/opt/cfncluster/scripts'

template '/etc/cfncluster/cfnconfig' do
  source 'cfnconfig.erb'
  mode '0644'
end

link '/opt/cfncluster/cfnconfig' do
  to '/etc/cfncluster/cfnconfig'
end

cookbook_file "fetch_and_run" do
  path "/opt/cfncluster/scripts/fetch_and_run"
  owner "root"
  group "root"
  mode "0755"
end

cookbook_file "compute_ready" do
  path "/opt/cfncluster/scripts/compute_ready"
  owner "root"
  group "root"
  mode "0755"
end
