return unless platform?('rocky') && node['platform_version'].to_i == 8

default['cluster']['cluster_user'] = 'rocky'
