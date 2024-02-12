default['cluster']['reserved_base_uid'] = 400

default['cluster']['cluster_admin_user'] = 'pcluster-admin'
default['cluster']['cluster_admin_user_id'] = node['cluster']['reserved_base_uid']
default['cluster']['cluster_admin_group'] = node['cluster']['cluster_admin_user']
default['cluster']['cluster_admin_group_id'] = node['cluster']['cluster_admin_user_id']
default['cluster']['cluster_admin_slurm_share_group'] = 'pcluster-slurm-share'
default['cluster']['cluster_admin_slurm_share_group_id'] = node['cluster']['reserved_base_uid'] + 5

# Slurm
default['cluster']['slurm']['user'] = 'slurm'
default['cluster']['slurm']['user_id'] = node['cluster']['reserved_base_uid'] + 1
default['cluster']['slurm']['group'] = node['cluster']['slurm']['user']
default['cluster']['slurm']['group_id'] = node['cluster']['slurm']['user_id']

# Munge
default['cluster']['munge']['user'] = 'munge'
default['cluster']['munge']['user_id'] = node['cluster']['reserved_base_uid'] + 2
default['cluster']['munge']['group'] = node['cluster']['munge']['user']
default['cluster']['munge']['group_id'] = node['cluster']['munge']['user_id']

default['cluster']['cluster_user_home'] = "/home/#{node['cluster']['cluster_user']}"
default['cluster']['cluster_user_local_home'] = "/local#{node['cluster']['cluster_user_home']}"
