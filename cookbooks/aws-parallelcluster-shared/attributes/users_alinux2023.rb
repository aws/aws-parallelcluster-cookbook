return unless platform?('amazon') && node['platform_version'].to_i == 2023

default['cluster']['cluster_user'] = 'ec2-user'
