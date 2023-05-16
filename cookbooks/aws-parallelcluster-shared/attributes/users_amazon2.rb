return unless platform?('amazon') && node['platform_version'] == "2"

default['cluster']['cluster_user'] = 'ec2-user'
