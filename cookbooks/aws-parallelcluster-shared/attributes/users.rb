default['cluster']['reserved_base_uid'] = 400

default['cluster']['cluster_admin_user'] = 'pcluster-admin'
default['cluster']['cluster_admin_user_id'] = node['cluster']['reserved_base_uid']
default['cluster']['cluster_admin_group'] = node['cluster']['cluster_admin_user']
default['cluster']['cluster_admin_group_id'] = node['cluster']['cluster_admin_user_id']

# Slurm
default['cluster']['slurm']['user'] = 'slurm'
default['cluster']['slurm']['user_id'] = node['cluster']['reserved_base_uid'] + 1
default['cluster']['slurm']['group'] = node['cluster']['slurm']['user']
default['cluster']['slurm']['group_id'] = node['cluster']['slurm']['user_id']
default['cluster']['slurm']['resume_group'] = 'slurm-resume'
default['cluster']['slurm']['resume_group_id'] = node['cluster']['reserved_base_uid'] + 5

# Munge
default['cluster']['munge']['user'] = 'munge'
default['cluster']['munge']['user_id'] = node['cluster']['reserved_base_uid'] + 2
default['cluster']['munge']['group'] = node['cluster']['munge']['user']
default['cluster']['munge']['group_id'] = node['cluster']['munge']['user_id']

default['cluster']['scheduler_plugin']['user'] = 'pcluster-scheduler-plugin'
default['cluster']['scheduler_plugin']['user_id'] = node['cluster']['reserved_base_uid'] + 4
default['cluster']['scheduler_plugin']['group'] = default['cluster']['scheduler_plugin']['user']
default['cluster']['scheduler_plugin']['group_id'] = default['cluster']['scheduler_plugin']['user_id']

default['cluster']['scheduler_plugin']['system_user_id_start'] = node['cluster']['reserved_base_uid'] + 10
default['cluster']['scheduler_plugin']['system_group_id_start'] = default['cluster']['scheduler_plugin']['system_user_id_start']
