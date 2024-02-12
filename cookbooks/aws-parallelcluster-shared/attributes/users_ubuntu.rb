return unless platform?('ubuntu')

default['cluster']['cluster_user'] = 'ubuntu'
default['cluster']['cluster_user_home'] = "/home/#{node['cluster']['cluster_user']}"
default['cluster']['cluster_user_local_home'] = "/local#{node['cluster']['cluster_user_home']}"
