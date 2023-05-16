return unless platform?('centos') && node['platform_version'].to_i == 7

default['cluster']['cluster_user'] = 'centos'
