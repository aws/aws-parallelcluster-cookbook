return unless platform?('centos') && node['platform_version'].to_i == 7

default['cluster']['cluster_user'] = 'centos'
default['cluster']['cluster_user_home'] = "/home/#{node['cluster']['cluster_user']}"
default['cluster']['cluster_user_local_home'] = "/local#{node['cluster']['cluster_user_home']}"
