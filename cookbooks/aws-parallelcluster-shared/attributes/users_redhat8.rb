return unless platform?('redhat') && node['platform_version'].to_i == 8

default['cluster']['cluster_user'] = 'ec2-user'
