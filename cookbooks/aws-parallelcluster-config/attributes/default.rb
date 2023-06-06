# aws-parallelcluster-config attributes

default['cluster']['raid_shared_dir'] = ''
default['cluster']['exported_raid_shared_dir'] = node['cluster']['raid_shared_dir']

default['cluster']['scheduler_slots'] = 'vcpus'
