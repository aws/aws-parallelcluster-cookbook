# Common attributes shared between multiple cookbooks

# Base dir

default['cluster']['head_node_home_path'] = '/home'
default['cluster']['shared_dir_compute'] = node['cluster']['shared_dir']
default['cluster']['shared_dir_head'] = node['cluster']['shared_dir']

default['cluster']['head_node_private_ip'] = nil
